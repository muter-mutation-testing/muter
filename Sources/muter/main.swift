import Darwin
import Foundation
import SwiftSyntax

func printUsageStatement() {
    print("""
    Muter, a mutation tester for Swift code

    usage:
    \tmuter [file]
    """)
}

func printMessage(_ message: String) {
    print("*******************************")
    print(message)
    print("*******************************")
}

func performMutationTesting(with configuration: MuterConfiguration) {

    let workingDirectoryPath = FileParser.createWorkingDirectory(in: configuration.projectDirectory)
    let discoveredFiles = discoverSourceCode(inDirectoryAt: configuration.projectDirectory)
    
    for filePath in discoveredFiles {
        let swapFilePath = FileParser.swapFilePath(forFileAt: filePath, using: workingDirectoryPath)
        FileParser.copySourceCode(fromFileAt: filePath, to: swapFilePath)
    }
    
    let tester = MutationTester(filePaths: discoveredFiles,
                                mutation: NegateConditionalsMutation(),
                                runTestSuite: testSuiteCommand(using: configuration.testCommandExecutable, and: configuration.testCommandArguments),
                                writeFile: { path, contents in try contents.write(toFile: path, atomically: true, encoding: .utf8) })
    tester.perform()
    
    for filePath in discoveredFiles {
        let swapFilePath = FileParser.swapFilePath(forFileAt: filePath, using: workingDirectoryPath)
        FileParser.copySourceCode(fromFileAt: swapFilePath, to: filePath)
    }
    
    removeWorkingDirectory(at: workingDirectoryPath)
}

func removeWorkingDirectory(at path: String) {
    do {
        try FileManager.default.removeItem(atPath: path)
    } catch {
        print("Encountered error removing Muter's working directory")
        print("\(error)")
    }
}

func discoverSourceCode(inDirectoryAt path: String) -> [String] {
    let discoveredFiles = FileParser.sourceFilesContained(in: path)
    let filePaths = discoveredFiles.joined(separator: "\n")
    printMessage("Discovered \(discoveredFiles.count) Swift files:\n\(filePaths)")
    
    return discoveredFiles
}

func mutateSourceCode(inFileAt path: String) {
    guard let sourceCode = FileParser.load(path: path) else {
        printMessage("Muter was unable to load the source file at path: \(path)")
        return
    }
    
    let mutatedSourceCode = NegateConditionalsMutation().mutate(source: sourceCode)
    try! mutatedSourceCode.description.write(toFile: path, atomically: true, encoding: .utf8)
}

func testSuiteCommand(using executablePath: String, and arguments: [String]) -> () -> Void {
    return {
        guard #available(OSX 10.13, *) else {
            print("muter is only supported on macOS 10.13 and higher")
            exit(1)
        }
    
        do {
            
            let url = URL(fileURLWithPath: executablePath)
            let process = try Process.run(url, arguments: arguments) {
                
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

switch CommandLine.argc {
case 2:
    let configurationPath = CommandLine.arguments[1]
    let configuration = try! JSONDecoder().decode(MuterConfiguration.self, from: FileManager.default.contents(atPath: configurationPath)!)
    
    performMutationTesting(with: configuration)
    
    exit(0)
default:
    printUsageStatement()
    exit(1)
}
