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

func runTestSuite() {
    if #available(OSX 10.13, *) {
        let url = URL(fileURLWithPath: "/usr/bin/xcodebuild")
        try! Process.run(url, arguments: [
            "-verbose",
            "-project",
            "/Users/seandorian/Code/Swift/muter/Tests/muterTests/fixtures/MuterExampleTestSuite/MuterExampleTestSuite.xcodeproj",
            "-scheme",
            "MuterExampleTestSuite",
            "-sdk",
            "iphonesimulator",
            "-destination",
            "platform=iOS Simulator,name=iPhone 6",
            "test",
        ]) { process in
            print("process finished running: \(!process.isRunning) \(process.terminationStatus)")

        }.waitUntilExit()
    } else {
        print("muter is only supported on macOS 10.13 and higher")
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
    let path = CommandLine.arguments[1]
    let workingDirectory = FileParser.createWorkingDirectory(in: path)
    let sourceFile = FileParser.sourceFilesContained(in: path).filter { $0.contains("Module")  && !$0.contains("Build")}[0]
    let swapFilePath = FileParser.swapFilePath(forFileAt: sourceFile, using: workingDirectory)

    FileParser.copySourceCode(fromFileAt: sourceFile, to: swapFilePath)
    mutateSourceCode(inFileAt: sourceFile)
    runTestSuite()
    FileParser.copySourceCode(fromFileAt: swapFilePath, to: sourceFile)
    
    exit(0)
default:
    printUsageStatement()
    exit(1)
}
