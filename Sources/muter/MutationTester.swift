import Foundation
protocol MutationTesterDelegate {
    func writeFile(filePath: String, contents: String) throws
    func runTestSuite()
    func restoreFile(at path: String) 
}

struct MutationTester {
    
    struct Delegate: MutationTesterDelegate {
        let configuration: MuterConfiguration
        
        func writeFile(filePath: String, contents: String) throws {
            try contents.write(toFile: filePath, atomically: true, encoding: .utf8)
        }
        func restoreFile(at path: String) {
            
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
    }
    
    let filePaths: [String]
    let mutation: SourceCodeMutation
    let delegate: MutationTesterDelegate

    func perform() {
        for path in filePaths {
            let sourceCode = FileParser.load(path: path)!
            
            if mutation.canMutate(source: sourceCode) {
                let mutatedSourceCode = mutation.mutate(source: sourceCode)
                try! delegate.writeFile(filePath: path, contents: mutatedSourceCode.description)
                delegate.runTestSuite()
            }
        }
    }
}
