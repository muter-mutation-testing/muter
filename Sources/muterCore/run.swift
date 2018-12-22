import Foundation

@available(OSX 10.12, *)
public func run(with configuration: MuterConfiguration, fileManager: FileManager = .default, in currentDirectoryPath: String) {
    let workingDirectoryPath = createWorkingDirectory(in: currentDirectoryPath)
    printMessage("Created working directory (muter_tmp) in:\n\n\(currentDirectoryPath)")

    printMessage("Discovering source code in:\n\n\(currentDirectoryPath)")
    let sourceFilePaths = discoverSourceFiles(inDirectoryAt: currentDirectoryPath, excludingPathsIn: configuration.blacklist)
    let swapFilePathsByOriginalPath = swapFilePaths(forFilesAt: sourceFilePaths, using: workingDirectoryPath)
    printDiscoveryMessage(for: sourceFilePaths)

    printMessage("Discovering applicable source code mutations in:\n\n\(currentDirectoryPath)")
    let mutations = discoverMutations(inFilesAt: sourceFilePaths)
    printDiscoveryMessage(for: mutations)

    fileManager.changeCurrentDirectoryPath(currentDirectoryPath)

    let testingDelegate = MutationTestingDelegate(configuration: configuration, swapFilePathsByOriginalPath: swapFilePathsByOriginalPath)
    let mutationScore = performMutationTesting(using: mutations, delegate: testingDelegate)

    removeWorkingDirectory(at: currentDirectoryPath + "/muter_tmp")
    printMessage("Removed working directory (muter_tmp) in:\n\n\(currentDirectoryPath)")

    printMessage("Muter finished running")
    printDiscoveryMessage(for: sourceFilePaths)
    printDiscoveryMessage(for: mutations)
    printMessage("Mutation Score of Test Suite (higher is better): \(mutationScore)/100")
}
