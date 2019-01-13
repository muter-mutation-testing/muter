import Foundation

public typealias ThrowingVoidClosure = () throws -> Void

// MARK - Commandline Argument Handler

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

// MARK - Mutation Test Run Handler

@available(OSX 10.13, *)
public func run(with configuration: MuterConfiguration,
                fileManager: FileSystemManager = FileManager.default,
                in currentDirectoryPath: String,
                performMutationTesting: (_ tempDirectoryPath: String, MuterConfiguration) -> Void = performMutationTesting(in:configuration:)) {
    do {    
        printMessage("Copying your project for mutation testing")

        let currentDirectoryUrl = URL(string: currentDirectoryPath)!

        let temporaryDirectory = try fileManager.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: currentDirectoryUrl, // The appropriateFor parameter is used to make sure the temp directory is on the same volume as the passed parameter.
            create: true // the create parameter is ignored when passing .itemReplacementDirectory
        )

        let destinationPath = destinationDirectoryPath(in: temporaryDirectory, withProjectName: currentDirectoryUrl.lastPathComponent)
        try fileManager.copyItem(atPath: currentDirectoryPath, toPath: destinationPath)
        
        performMutationTesting(destinationPath, configuration)

    } catch {
        fatalError("""
            Muter was unable to create a temporary directory,
            or was unable to copy your project, and cannot continue.
            
            If you can reproduce this, please consider filing a bug
            at https://github.com/SeanROlszewski/muter

            Please include the following in the bug report:
            *********************
            FileManager error: \(error)
            """)
    }
}

@available(OSX 10.13, *)
public func performMutationTesting(in currentDirectoryPath: String, configuration: MuterConfiguration) {
    let workingDirectoryPath = createWorkingDirectory(in: currentDirectoryPath)
    printMessage("Created working directory (muter_tmp) in:\n\n\(currentDirectoryPath)")

    printMessage("Discovering source code in:\n\n\(currentDirectoryPath)")
    let sourceFilePaths = discoverSourceFiles(inDirectoryAt: currentDirectoryPath, excludingPathsIn: configuration.blacklist)
    let swapFilePathsByOriginalPath = swapFilePaths(forFilesAt: sourceFilePaths, using: workingDirectoryPath)
    printDiscoveryMessage(for: sourceFilePaths)

    printMessage("Discovering applicable source code mutations in:\n\n\(currentDirectoryPath)")
    let mutations = discoverMutationOperators(inFilesAt: sourceFilePaths)
    printDiscoveryMessage(for: mutations)

    FileManager.default.changeCurrentDirectoryPath(currentDirectoryPath)

    printMessage("Beginning mutation testing")
    let testingDelegate = MutationTestingDelegate(configuration: configuration, swapFilePathsByOriginalPath: swapFilePathsByOriginalPath)
    let mutationTestingResults = performMutationTesting(using: mutations, delegate: testingDelegate)
    let testReport = generateTestReport(from: mutationTestingResults)

    printMessage(testReport)
}

private func destinationDirectoryPath(in temporaryDirectory: URL, withProjectName name: String) -> String {
    let destination = temporaryDirectory.appendingPathComponent(name, isDirectory: true)
    return destination.path
}

// MARK - Setup Handler

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
