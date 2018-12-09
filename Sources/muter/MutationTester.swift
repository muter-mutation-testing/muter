import Foundation
import SwiftSyntax

func swapFilePaths(for discoveredFiles: [String], using workingDirectoryPath: String) ->  [String: String] {
    var swapFilePathsByOriginalPath: [String: String] = [:]
    for filePath in discoveredFiles {
        let swapFilePath = FileUtilities.swapFilePath(forFileAt: filePath, using: workingDirectoryPath)
        swapFilePathsByOriginalPath[filePath] = swapFilePath
    }
    return swapFilePathsByOriginalPath
}

func mutationScore(from testResults: [MutationTester.TestSuiteResult]) -> Int {
    guard testResults.count >= 1 else {
        return -1
    }
    
    let numberOfFailures = Double(testResults.filter { $0 == .failed }.count)
    return Int((numberOfFailures / Double(testResults.count)) * 100.0)
}

protocol MutationTesterDelegate {
    func backupFile(at path: String)
    func runTestSuite() -> MutationTester.TestSuiteResult
    func restoreFile(at path: String) 
}

class MutationTester {
    
    let mutations: [SourceCodeMutation]
    let delegate: MutationTesterDelegate
    var testSuiteResults: [TestSuiteResult]

    var overallMutationScore: Int {
        return mutationScore(from: testSuiteResults)
    }

    init(mutations: [SourceCodeMutation], delegate: MutationTesterDelegate) {
        self.mutations = mutations
        self.delegate = delegate
        self.testSuiteResults = []
    }
    
    func perform() {
        
        for mutation in mutations {
            delegate.backupFile(at: mutation.filePath)
            
            mutation.mutate()
            
            let result = delegate.runTestSuite()
            testSuiteResults.append(result)
            
            delegate.restoreFile(at: mutation.filePath)
        }
    }
}

extension MutationTester {
    enum TestSuiteResult {
        case passed
        case failed
    }
    
    struct Delegate: MutationTesterDelegate {
        let configuration: MuterConfiguration
        let swapFilePathsByOriginalPath: [String: String]
  
        func runTestSuite() -> MutationTester.TestSuiteResult {
            guard #available(OSX 10.13, *) else {
                print("muter is only supported on macOS 10.13 and higher")
                exit(1)
            }
            
            var testResult: MutationTester.TestSuiteResult!

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
            FileUtilities.copySourceCode(fromFileAt: path, to: swapFilePath)
        }
        
        func restoreFile(at path: String) {
            printMessage("Restoring file at \(path)")
            let swapFilePath = swapFilePathsByOriginalPath[path]!
            FileUtilities.copySourceCode(fromFileAt: swapFilePath, to: path)
        }
    }
}
