import Darwin
import Foundation
import SwiftSyntax

func run(with configuration: MuterConfiguration) {

    let workingDirectoryPath = FileUtilities.createWorkingDirectory(in: configuration.projectDirectory)
    let discoveredFilesPaths = discoverSourceCode(inDirectoryAt: configuration.projectDirectory)
    let mutations = discoverMutations(inFilesAt: discoveredFilesPaths)
    
    let mutatedFilePaths = mutations.map { $0.filePath }.deduplicated.sorted().joined(separator: "\n")
    printMessage("Discovered \(mutations.count) mutations to introduce in the following files: \n\(mutatedFilePaths)")
    
    let delegate = MutationTester.Delegate(configuration: configuration,
                                           swapFilePathsByOriginalPath: swapFilePaths(for: discoveredFilesPaths, using: workingDirectoryPath))
    
    let tester = MutationTester(mutations: mutations,
                                delegate: delegate)
    tester.perform()

    printMessage("Mutation Score of Test Suite: \(tester.overallMutationScore)%")
    
    removeWorkingDirectory(at: workingDirectoryPath)
}

func removeWorkingDirectory(at path: String) {
    do {
        try FileManager.default.removeItem(atPath: path)
    } catch {
        print("Encountered error removing Muter's working directory")
        print("\(error)")
    }
}

func discoverSourceCode(inDirectoryAt path: String) -> [String] {
    let discoveredFiles = FileUtilities.sourceFilesContained(in: path)
    let filePaths = discoveredFiles.joined(separator: "\n")
    printMessage("Discovered \(discoveredFiles.count) Swift files:\n\(filePaths)")
    
    return discoveredFiles
}

switch CommandLine.argc {
case 2:
    let configurationPath = CommandLine.arguments[1]
    let configuration = try! JSONDecoder().decode(MuterConfiguration.self, from: FileManager.default.contents(atPath: configurationPath)!)
    
    run(with: configuration)
    
    exit(0)
default:
    printUsageStatement()
    exit(1)
}
