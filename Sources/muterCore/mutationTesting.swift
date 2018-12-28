import Foundation
import SwiftSyntax

protocol MutationTestingIODelegate {
    func backupFile(at path: String)
    func runTestSuite() -> TestSuiteResult
    func restoreFile(at path: String) 
}

struct MutationTestOutcome: Equatable {
    let testSuiteResult: TestSuiteResult
    let appliedMutation: String
    let filePath: String
}

enum TestSuiteResult: String {
    case passed
    case failed
	
	var asMutationTestingResult: String {
		switch self {
		case .passed:
			return "failed"
		default:
			return "passed"
		}
	}
}

func performMutationTesting(using mutations: [SourceCodeMutation], delegate: MutationTestingIODelegate) -> [MutationTestOutcome] {
    
    return mutations.map { mutation in
        delegate.backupFile(at: mutation.filePath)
        
        mutation.mutate()
        
        let result = delegate.runTestSuite()
        delegate.restoreFile(at: mutation.filePath)
        
        return MutationTestOutcome(testSuiteResult: result,
								   appliedMutation: "\(type(of: mutation))",
								   filePath: mutation.filePath)
    }
}

// MARK - Mutation Score Calculation

func mutationScore(from testResults: [TestSuiteResult]) -> Int {
    guard testResults.count >= 1 else {
        return -1
    }
    
    let numberOfFailures = Double(testResults.filter { $0 == .failed }.count)
    return Int((numberOfFailures / Double(testResults.count)) * 100.0)
}

func mutationScoreOfFiles(from outcomes: [MutationTestOutcome]) -> [String: Int] {
	var mutationScores: [String: Int] = [:]
	
	let filePaths = outcomes.map { $0.filePath }.deduplicated()
	for filePath in filePaths {
		let relevantTestResults = outcomes.filter { $0.filePath == filePath }
		let testSuiteResults = relevantTestResults.map { $0.testSuiteResult }
		mutationScores[filePath] = mutationScore(from: testSuiteResults)
	}
	
	return mutationScores
}

// MARK - Mutation Testing I/O Delegate

struct MutationTestingDelegate: MutationTestingIODelegate {
    let configuration: MuterConfiguration
    let swapFilePathsByOriginalPath: [String: String]
    
    func runTestSuite() -> TestSuiteResult {
        guard #available(OSX 10.13, *) else {
            print("muter is only supported on macOS 10.13 and higher")
            exit(1)
        }
        
        var testResult: TestSuiteResult!
        
        do {
            let url = URL(fileURLWithPath: configuration.testCommandExecutable)
            
            let process = try Process.run(url, arguments: configuration.testCommandArguments) {
                
                testResult = $0.terminationStatus > 0 ? .failed : .passed
                
                let testStatus = testResult == .failed ?
                    "\t✅ Mutation Test Passed " :
                "\t❌ Mutation Test Failed"
                
                printMessage("Test Suite finished running\n\(testStatus)")
            }
            
            process.waitUntilExit()
            
        } catch {
            printMessage("muter encountered an error running your test suite and can't continue\n\(error)")
            exit(1)
        }
        
        return testResult
    }
    
    func backupFile(at path: String) {
        printMessage("Backing up file at \(path)")
        let swapFilePath = swapFilePathsByOriginalPath[path]!
        copySourceCode(fromFileAt: path, to: swapFilePath)
    }
    
    func restoreFile(at path: String) {
        printMessage("Restoring file at \(path)")
        let swapFilePath = swapFilePathsByOriginalPath[path]!
        copySourceCode(fromFileAt: swapFilePath, to: path)
    }
}

