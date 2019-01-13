import Foundation

public func printHeader() {
    print(
    """


    _____       _             
    |     | _ _ | |_  ___  ___ 
    | | | || | ||  _|| -_||  _|
    |_|_|_||___||_|  |___||_|  


    Automated mutation testing for Swift

    Need help?
    https://github.com/SeanROlszewski/muter/issues


    """)
}

func printMessage(_ message: String) {
    print("*******************************")
    print(message)
    print("")
}

func printDiscoveryMessage(for discoveredFilePaths: [String]) {
    let filePaths = discoveredFilePaths.joined(separator: "\n")
    printMessage("Discovered \(discoveredFilePaths.count) Swift files:\n\n\(filePaths)")
}

func printDiscoveryMessage(for discoveredMutationOperators: [MutationOperator]) {
    printMessage("Discovered \(discoveredMutationOperators.count) mutations to introduce:\n")

    for (index, mutation) in discoveredMutationOperators.enumerated() {
        let listPosition = "\(index+1))"
        let fileName = URL(fileURLWithPath: mutation.filePath).lastPathComponent
        print("\(listPosition) \(fileName)")
    }
}
