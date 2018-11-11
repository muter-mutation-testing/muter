import SwiftSyntax
import Darwin
import Foundation

func printUsageStatement() {
    print("""
        Muter, a mutation tester for Swift code

        usage:
        \tmuter [file]
        """)
}
let testCommand = """
xcodebuild \
-project ./MuterExampleTestSuite.xcodeproj \
-scheme MuterExampleTestSuite \
-sdk iphonesimulator \
-destination 'platform=iOS Simulator,name=iPhone 6' \
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
            ]) { (process) in
                print("process finished running: \(!process.isRunning) \(process.terminationStatus)")
                
            }.waitUntilExit()
    } else {
        print("muter is only supported on macOS 10.13 and higher")
        exit(1)
    }
}

func copyOriginalSourceCode(fromFileAt path: String) {
    try! FileManager.default.createDirectory(atPath: "/Users/seandorian/Code/Swift/muter/Tests/muterTests/fixtures/muter_tmp/MuterExampleTestSuite/MuterExampleTestSuite", withIntermediateDirectories: true, attributes: nil)
    let swapFile = "/Users/seandorian/Code/Swift/muter/Tests/muterTests/fixtures/muter_tmp/MuterExampleTestSuite/MuterExampleTestSuite/Module.swift"
    
    
    let sourceCode = try! FileParser().load(path: path)
    try! sourceCode.description.write(toFile: swapFile, atomically: true, encoding: .utf8)
}

func mutateSourceCode(inFileAt path: String) {
    let sourceCode = try! FileParser().load(path: path)
    
    let mutatedSourceCode = NegateConditionalsMutation().mutate(source: sourceCode)
    
    try! mutatedSourceCode.description.write(toFile: path, atomically: true, encoding: .utf8)
}

func restoreSourceCode(forFileAt path: String) {
    let swapFile = "/Users/seandorian/Code/Swift/muter/Tests/muterTests/fixtures/muter_tmp/MuterExampleTestSuite/MuterExampleTestSuite/Module.swift"
    
    
    let sourceCode = try! FileParser().load(path: swapFile)
    try! sourceCode.description.write(toFile: path, atomically: true, encoding: .utf8)
}

switch CommandLine.argc {
case 2:
//    let path = CommandLine.arguments[1]
    let path = "/Users/seandorian/Code/Swift/muter/Tests/muterTests/fixtures/MuterExampleTestSuite/MuterExampleTestSuite/Module.swift"
    
    copyOriginalSourceCode(fromFileAt: path)
    mutateSourceCode(inFileAt: path)
    runTestSuite()
    restoreSourceCode(forFileAt: path)
    
    exit(0)
default:
    printUsageStatement()
    exit(1)
}
