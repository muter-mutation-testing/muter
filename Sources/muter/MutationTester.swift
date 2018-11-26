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
    func runTestSuite()
    func restoreFile(at path: String) 
}

struct MutationTester {
    
    struct Delegate: MutationTesterDelegate {
        let configuration: MuterConfiguration
        let swapFilePathsByOriginalPath: [String: String]
        
        func sourceFromFile(at path: String) -> SourceFileSyntax? {
            return FileParser.load(path: path)
        }
        
        func writeFile(filePath: String, contents: String) throws {
            try contents.write(toFile: filePath, atomically: true, encoding: .utf8)
        }
        
        func runTestSuite() {
            guard #available(OSX 10.13, *) else {
                print("muter is only supported on macOS 10.13 and higher")
                exit(1)
            }
            
            do {
                let url = URL(fileURLWithPath: configuration.testCommandExecutable)
                let process = try Process.run(url, arguments: configuration.testCommandArguments) {
                    
                    let testStatus = $0.terminationStatus > 0 ?
                        "\t✅ Mutation Test Passed " :
                    "\t❌ Mutation Test Failed"
                    
                    printMessage("Test Suite finished running\n\(testStatus)")
                }
                
                process.waitUntilExit()
                
            } catch {
                printMessage("muter encountered an error running your test suite and can't continue\n\(error)")
                exit(1)
            }
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
    
    let filePaths: [String]
    let mutation: SourceCodeMutation
    let delegate: MutationTesterDelegate

    func perform() {
        for path in filePaths {
            let sourceCode = delegate.sourceFromFile(at: path)!
            
            if mutation.canMutate(source: sourceCode) {
                delegate.backupFile(at: path)
                let mutatedSourceCode = mutation.mutate(source: sourceCode)
                try! delegate.writeFile(filePath: path, contents: mutatedSourceCode.description)
                delegate.runTestSuite()
                delegate.restoreFile(at: path)
            }
        }
    }
}
