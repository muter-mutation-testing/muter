import Darwin
import Foundation
import SwiftSyntax

@available(OSX 10.12, *)
func run(with configuration: MuterConfiguration) {

    let workingDirectoryPath = FileUtilities.createWorkingDirectory(in: FileManager.default.currentDirectoryPath)
    let discoveredFilesPaths = discoverSourceCode(inDirectoryAt: FileManager.default.currentDirectoryPath)

    let mutations = discoverMutations(inFilesAt: discoveredFilesPaths)
    
    let mutatedFilePaths = mutations.map{ $0.filePath }.deduplicated().sorted().joined(separator: "\n")
    printMessage("Discovered \(mutations.count) mutations to introduce in the following files: \n\(mutatedFilePaths)")
    
    let delegate = MutationTester.Delegate(configuration: configuration,
                                           swapFilePathsByOriginalPath: swapFilePaths(for: discoveredFilesPaths, using: workingDirectoryPath))
    
    FileManager.default.changeCurrentDirectoryPath(FileManager.default.currentDirectoryPath)
    
    let tester = MutationTester(mutations: mutations,
                                delegate: delegate)
    tester.perform()

    printMessage("Mutation Score of Test Suite: \(tester.overallMutationScore)/100")
    
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

func discoverSourceCode(inDirectoryAt path: String) -> [String] {
    let discoveredFiles = FileUtilities.sourceFilesContained(in: path)
    let filePaths = discoveredFiles.joined(separator: "\n")
    
    printMessage("Discovered \(discoveredFiles.count) Swift files:\n\(filePaths)")
    
    return discoveredFiles
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
