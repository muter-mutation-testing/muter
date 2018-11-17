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

func copyOriginalSourceCode(fromFileAt path: String, into workingDirectory: String) {
    let swapFilePath = "\(workingDirectory)/Module.swift"
    FileParser.copySourceCode(fromFileAt: path, to: swapFilePath)
}

func mutateSourceCode(inFileAt path: String) {
    let sourceCode = FileParser.load(path: path)
    let mutatedSourceCode = NegateConditionalsMutation().mutate(source: sourceCode!)
    try! mutatedSourceCode.description.write(toFile: path, atomically: true, encoding: .utf8)
}

func restoreSourceCode(forFileAt path: String, from workingDirectory: String) {
    let swapFilePath = "\(workingDirectory)/Module.swift"
    FileParser.copySourceCode(fromFileAt: swapFilePath, to: path)
}

switch CommandLine.argc {
case 2:
//    let path = CommandLine.arguments[1]
    let path = "/Users/seandorian/Code/Swift/muter/Tests/muterTests/fixtures/MuterExampleTestSuite/MuterExampleTestSuite/Module.swift"
    let workingDirectory = FileParser.createWorkingDirectory(in: "/Users/seandorian/Code/Swift/muter/Build/Products/Debug")

    copyOriginalSourceCode(fromFileAt: path, into: workingDirectory)
    mutateSourceCode(inFileAt: path)
    runTestSuite()
    restoreSourceCode(forFileAt: path, from: workingDirectory)

    exit(0)
default:
    printUsageStatement()
    exit(1)
}
