import Darwin
import Foundation
import SwiftSyntax

@available(OSX 10.12, *)
func run(with configuration: MuterConfiguration) {

    let workingDirectoryPath = createWorkingDirectory(in: FileManager.default.currentDirectoryPath)
    let filePaths = discoverSourceFiles(inDirectoryAt: FileManager.default.currentDirectoryPath)
    let mutations = discoverMutations(inFilesAt: filePaths)
    let testingDelegate = MutationTestingDelegate(configuration: configuration,
                                           swapFilePathsByOriginalPath: swapFilePaths(for: filePaths, using: workingDirectoryPath))
    
    FileManager.default.changeCurrentDirectoryPath(FileManager.default.currentDirectoryPath)
    
    printDiscoveryMessage(for: filePaths, and: mutations)
    let mutationScore = performMutationTesting(using: mutations, delegate: testingDelegate)
    printMessage("Mutation Score of Test Suite: \(mutationScore)/100")
    
    removeWorkingDirectory(at: FileManager.default.currentDirectoryPath +
        "/muter_tmp")
}

func removeWorkingDirectory(at path: String) {
    do {
        try FileManager.default.removeItem(atPath: path)
    } catch {
        printMessage("Encountered error removing Muter's working directory")
        printMessage("\(error)")
    }
}

if #available(OSX 10.13, *) {
    let configurationPath = FileManager.default.currentDirectoryPath + "/muter.conf.json"
    let configuration = try! JSONDecoder().decode(MuterConfiguration.self, from: FileManager.default.contents(atPath: configurationPath)!)
    
    run(with: configuration)
    
    exit(0)
} else {
    print("Muter requires macOS 10.13 or higher")
    exit(1)
}
