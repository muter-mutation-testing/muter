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

func printDiscoveryMessage(for discoveredFiles: [String], and discoveredMutations: [SourceCodeMutation]) {
    let filePaths = discoveredFiles.joined(separator: "\n")
    printMessage("Discovered \(discoveredFiles.count) Swift files:\n\(filePaths)")
    
    let mutatedFilePaths = discoveredMutations.map{ $0.filePath }.deduplicated().sorted().joined(separator: "\n")
    printMessage("Discovered \(discoveredMutations.count) mutations to introduce in the following files: \n\(mutatedFilePaths)")
    
}
