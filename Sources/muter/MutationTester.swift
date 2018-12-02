import Foundation
import SwiftSyntax

func swapFilePaths(for discoveredFiles: [String], using workingDirectoryPath: String) ->  [String: String] {
    var swapFilePathsByOriginalPath: [String: String] = [:]
    for filePath in discoveredFiles {
        let swapFilePath = FileParser.swapFilePath(forFileAt: filePath, using: workingDirectoryPath)
        swapFilePathsByOriginalPath[filePath] = swapFilePath
    }
    return swapFilePathsByOriginalPath
}

protocol MutationTesterDelegate {
    func sourceFromFile(at path: String) -> SourceFileSyntax?
    func backupFile(at path: String)
    func writeFile(filePath: String, contents: String) throws
    func runTestSuite() -> MutationTester.TestSuiteResult
    func restoreFile(at path: String) 
}

class MutationTester {
    
    let filePaths: [String]
    let mutation: SourceCodeMutation
    let delegate: MutationTesterDelegate
    private var testSuiteResults: [TestSuiteResult]

    var mutationScore: Int {
        guard testSuiteResults.count >= 1 else {
            return -1
        }
        
        let numberOfFailures = testSuiteResults.filter { $0 == .failed }.count
        return (numberOfFailures / testSuiteResults.count) * 100
    }

    init(filePaths: [String], mutation: SourceCodeMutation, delegate: MutationTesterDelegate) {
        self.filePaths = filePaths
        self.mutation = mutation
        self.delegate = delegate
        self.testSuiteResults = []
    }
    
    func perform() {
        for path in filePaths {
            let sourceCode = delegate.sourceFromFile(at: path)!
            
            if mutation.canMutate(source: sourceCode) {
                delegate.backupFile(at: path)
                let mutatedSourceCode = mutation.mutate(source: sourceCode)
                try! delegate.writeFile(filePath: path, contents: mutatedSourceCode.description)
                
                let result = delegate.runTestSuite()
                testSuiteResults.append(result)
                
                delegate.restoreFile(at: path)
            }
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
        
        func sourceFromFile(at path: String) -> SourceFileSyntax? {
            return FileParser.load(path: path)
        }
        
        func writeFile(filePath: String, contents: String) throws {
            try contents.write(toFile: filePath, atomically: true, encoding: .utf8)
        }
        
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
            let swapFilePath = swapFilePathsByOriginalPath[path]!
            FileParser.copySourceCode(fromFileAt: path, to: swapFilePath)
        }
        
        func restoreFile(at path: String) {
            let swapFilePath = swapFilePathsByOriginalPath[path]!
            FileParser.copySourceCode(fromFileAt: swapFilePath, to: path)
        }
    }
}
