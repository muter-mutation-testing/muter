import Darwin
import Foundation
import SwiftSyntax

@available(OSX 10.12, *)
func run(with configuration: MuterConfiguration, fileManager: FileManager = .default, in currentDirectoryPath: String) {
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

    printMessage("Mutation Score of Test Suite: \(mutationScore)/100")
}

if #available(OSX 10.13, *) {
    let configurationPath = FileManager.default.currentDirectoryPath + "/muter.conf.json"
    let configuration = try! JSONDecoder().decode(MuterConfiguration.self, from: FileManager.default.contents(atPath: configurationPath)!)
    
    run(with: configuration, in: FileManager.default.currentDirectoryPath)
    
    exit(0)
} else {
    print("Muter requires macOS 10.13 or higher")
    exit(1)
}
