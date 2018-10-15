import SwiftSyntax
import Darwin

func printUsageStatement() {
    print("""
        Muter, a mutation tester for Swift code

        usage:
        \tmuter [file]
        """)
}

switch CommandLine.argc {
case 2:
    let path = CommandLine.arguments[1]
    print("Mutated file at \(path)")
    
    
    exit(0)
default:
    printUsageStatement()
    exit(1)
}






