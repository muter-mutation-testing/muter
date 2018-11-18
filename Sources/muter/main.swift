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

let testCommand = """
xcodebuild \
-project ./muter.xcodeproj \
-scheme MuterTestSuite \
-sdk macosx \
-destination 'platform=macosx' \
test
"""

func runTestSuite(using executablePath: String, and arguments: [String]) {
    guard #available(OSX 10.13, *) else {
        print("muter is only supported on macOS 10.13 and higher")
        exit(1)
    }
    
    do {
        let url = URL(fileURLWithPath: executablePath)
        let process = try Process.run(url, arguments: arguments) { print("process finished running: \(!$0.isRunning) \($0.terminationStatus)") }
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

switch CommandLine.argc {
case 2:

    let configurationPath = CommandLine.arguments[1]
    
    let configuration = try! JSONDecoder().decode(MuterConfiguration.self, from: FileManager.default.contents(atPath: configurationPath)!)

    let workingDirectory = FileParser.createWorkingDirectory(in: configuration.projectDirectory)
    let sourceFile = FileParser.sourceFilesContained(in: configuration.projectDirectory).filter { $0.contains("Module")  && !$0.contains("Build")}[0]
    let swapFilePath = FileParser.swapFilePath(forFileAt: sourceFile, using: workingDirectory)

    FileParser.copySourceCode(fromFileAt: sourceFile, to: swapFilePath)
    mutateSourceCode(inFileAt: sourceFile)
    runTestSuite(using: configuration.testCommandExecutable, and: configuration.testCommandArguments)
    FileParser.copySourceCode(fromFileAt: swapFilePath, to: sourceFile)
    
    exit(0)
default:
    printUsageStatement()
    exit(1)
}
