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

func runTestSuite(using executablePath: String, and arguments: [String]) {
    guard #available(OSX 10.13, *) else {
        print("muter is only supported on macOS 10.13 and higher")
        exit(1)
    }
    
    do {
        let url = URL(fileURLWithPath: executablePath)
        let process = try Process.run(url, arguments: arguments) {
            print("*******************************")
            print("Test Suite finished running\n")
            print($0.terminationStatus > 0 ?
                "\t✅ Mutation Test Passed " :
                "\t❌ Mutation Test Failed")
            print("*******************************")
        }
        process.waitUntilExit()
    } catch  {
        print("muter encountered an error running your test suite and can't continue")
        print(error)
        exit(1)
    }
}

func mutateSourceCode(inFileAt path: String) {
    let sourceCode = FileParser.load(path: path)!
    let mutatedSourceCode = NegateConditionalsMutation().mutate(source: sourceCode)
    try! mutatedSourceCode.description.write(toFile: path, atomically: true, encoding: .utf8)
}

func discoverSourceCode(inDirectoryAt path: String) -> [String] {
    let discoveredFiles = FileParser
        .sourceFilesContained(in: path)
    
    
    print("*******************************")
    print("Discovered \(discoveredFiles.count) Swift files:")
    print(discoveredFiles.joined(separator: "\n"))
    print("*******************************")
    
    return discoveredFiles
}

switch CommandLine.argc {
case 2:
    
    let configurationPath = CommandLine.arguments[1]
    let configuration = try! JSONDecoder().decode(MuterConfiguration.self, from: FileManager.default.contents(atPath: configurationPath)!)
    
    let workingDirectory = FileParser.createWorkingDirectory(in: configuration.projectDirectory)
    let discoveredFiles = discoverSourceCode(inDirectoryAt: configuration.projectDirectory)
    
    let sourceFile = discoveredFiles.filter { $0.contains("Module")}[0]
    let swapFilePath = FileParser.swapFilePath(forFileAt: sourceFile, using: workingDirectory)
    
    FileParser.copySourceCode(fromFileAt: sourceFile, to: swapFilePath)
    mutateSourceCode(inFileAt: sourceFile)
    runTestSuite(using: configuration.testCommandExecutable, and: configuration.testCommandArguments)
    FileParser.copySourceCode(fromFileAt: swapFilePath, to: sourceFile)
    
    do {
        try FileManager.default.removeItem(atPath: workingDirectory)
    } catch {
        print("Encountered error removing Muter's working directory")
        print("\(error)")
    }
    
    exit(0)
default:
    printUsageStatement()
    exit(1)
}
