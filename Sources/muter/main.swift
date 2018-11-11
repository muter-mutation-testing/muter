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



switch CommandLine.argc {
case 2:
    let path = CommandLine.arguments[1]

    if #available(OSX 10.13, *) {
        let url = URL(fileURLWithPath: "/usr/bin/xcodebuild")
        try Process.run(url, arguments: [
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
            print("process finished running: \(process.isRunning)")
        }.waitUntilExit()
        
    } else {
        // Fallback on earlier versions
    }
    
    exit(0)
default:
    printUsageStatement()
    exit(1)
}






