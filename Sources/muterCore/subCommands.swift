import Foundation

public typealias ThrowingVoidClosure = () throws -> Void

@available(OSX 10.13, *)
public func run(with configuration: MuterConfiguration, fileManager: FileManager = .default, in currentDirectoryPath: String) {
    let workingDirectoryPath = createWorkingDirectory(in: currentDirectoryPath)
    printMessage("Created working directory (muter_tmp) in:\n\n\(currentDirectoryPath)")

    printMessage("Discovering source code in:\n\n\(currentDirectoryPath)")
    let sourceFilePaths = discoverSourceFiles(inDirectoryAt: currentDirectoryPath, excludingPathsIn: configuration.blacklist)
    let swapFilePathsByOriginalPath = swapFilePaths(forFilesAt: sourceFilePaths, using: workingDirectoryPath)
    printDiscoveryMessage(for: sourceFilePaths)

    printMessage("Discovering applicable source code mutations in:\n\n\(currentDirectoryPath)")
    let mutations = discoverMutationOperators(inFilesAt: sourceFilePaths)
    printDiscoveryMessage(for: mutations)

    fileManager.changeCurrentDirectoryPath(currentDirectoryPath)

	printMessage("Beginning mutation testing")
    let testingDelegate = MutationTestingDelegate(configuration: configuration, swapFilePathsByOriginalPath: swapFilePathsByOriginalPath)
    let mutationTestingResults = performMutationTesting(using: mutations, delegate: testingDelegate)
	let testReport = generateTestReport(from: mutationTestingResults)
	
    removeWorkingDirectory(at: currentDirectoryPath + "/muter_tmp")
    printMessage("Removed working directory (muter_tmp) in:\n\n\(currentDirectoryPath)")
	printMessage(testReport)
}

@available(OSX 10.13, *)
public func setupMuter(using manager: FileManager, and directory: String) throws {
    let configuration = MuterConfiguration(executable: "absolute path to the executable that runs your tests", 
                                           arguments: ["an argument the test runner needs", "another argument the test runner needs"], 
                                           blacklist: [])
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try! encoder.encode(configuration)

    manager.createFile(atPath: "\(directory)/muter.conf.json", 
                       contents: data, 
                       attributes: nil)
}

public func handle(commandlineArguments: [String], setup: ThrowingVoidClosure, run running: ThrowingVoidClosure) -> (Int32, String?) {
    switch commandlineArguments.count {
        case 2:
            guard commandlineArguments[1] == "init" else {
                return (1, "Unrecognized subcommand given to Muter\nAvailable subcommands:\n\n\tinit")
            }

            do {
                try setup()
                return (0, "Created muter config file at: \(FileManager.default.currentDirectoryPath)/muter.config.json")
            } catch {
                return (1, "Error creating muter config file\n\n\(error)")
            }
        default: 
            do {
                try running()
                return (0, nil)
            } catch {
                return (1, "Error running Muter - make sure your config file exists and is filled out correctly\n\n\(error)")
            }
    }
}
