func printMessage(_ message: String) {
    print("*******************************")
    print(message)
}

func printDiscoveryMessage(for discoveredFilePaths: [String], and discoveredMutations: [SourceCodeMutation]) {
    let filePaths = discoveredFilePaths.joined(separator: "\n")
    printMessage("Discovered \(discoveredFilePaths.count) Swift files:\n\(filePaths)")
    
    let mutatedFilePaths = discoveredMutations.map{ $0.filePath }.deduplicated().sorted().joined(separator: "\n")
    printMessage("Discovered \(discoveredMutations.count) mutations to introduce in the following files: \n\(mutatedFilePaths)")
}
