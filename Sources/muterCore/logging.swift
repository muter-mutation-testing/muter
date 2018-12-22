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

func printDiscoveryMessage(for discoveredMutations: [SourceCodeMutation]) {
    printMessage("Discovered \(discoveredMutations.count) mutations to introduce:\n")
    
    for (index, mutation) in discoveredMutations.enumerated() {
        let listPosition = "\(index+1))"
        let fileName = URL(string: mutation.filePath)!.lastPathComponent
        let sourceCodePosition = "(Line: \(mutation.rewriter.positionToMutate.line), Column: \(mutation.rewriter.positionToMutate.column))"
        
        print("\(listPosition) \(fileName) \(sourceCodePosition)")
    }
}
