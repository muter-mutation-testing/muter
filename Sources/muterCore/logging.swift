import Foundation
func printMessage(_ message: String) {
    print("*******************************")
    print(message)
    print("")
}

func printDiscoveryMessage(for discoveredFilePaths: [String]) {
    let filePaths = discoveredFilePaths.joined(separator: "\n")
    printMessage("Discovered \(discoveredFilePaths.count) Swift files:\n\n\(filePaths)")
}

func printDiscoveryMessage(for discoveredMutations: [MutationOperator]) {
    printMessage("Discovered \(discoveredMutations.count) mutations to introduce:\n")
    
    for (index, mutation) in discoveredMutations.enumerated() {
        let listPosition = "\(index+1))"
        let fileName = URL(string: mutation.filePath)!.lastPathComponent		
        print("\(listPosition) \(fileName)")
    }
}
