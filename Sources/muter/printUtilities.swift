func printUsageStatement() {
    print("""
    Muter, a mutation tester for Swift code

    usage:
    \tmuter configuration_file_path
    """)
}

func printMessage(_ message: String) {
    print("*******************************")
    print(message)
}
