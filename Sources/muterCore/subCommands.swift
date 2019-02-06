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
public func run(with configuration: MuterConfiguration, in path: String) {

    let currentDirectory = URL(fileURLWithPath: path)
    let destinationPath = copyProject(in: currentDirectory)
    let report = beginMutationTesting(in: destinationPath, with: configuration)
    save(report, to: currentDirectory)

}

public func copyProject(in currentDirectory: URL, using fileManager: FileSystemManager = FileManager.default) -> String {
    do {

        let temporaryDirectory = try fileManager.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: currentDirectory, // The appropriateFor parameter is used to make sure the temp directory is on the same volume as the passed parameter.
            create: true // the create parameter is ignored when passing .itemReplacementDirectory
        )

        let destinationPath = destinationDirectoryPath(in: temporaryDirectory, withProjectName: currentDirectory.lastPathComponent)
        print("Copying your project for mutation testing")
        try fileManager.copyItem(atPath: currentDirectory.path, toPath: destinationPath)
        return destinationPath

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

private func destinationDirectoryPath(in temporaryDirectory: URL, withProjectName name: String) -> String {
    let destination = temporaryDirectory.appendingPathComponent(name, isDirectory: true)
    return destination.path
}

@available(OSX 10.13, *)
public func beginMutationTesting(in currentDirectoryPath: String, with configuration: MuterConfiguration) -> MuterTestReport? {
    let workingDirectoryPath = createWorkingDirectory(in: currentDirectoryPath)
    printMessage("Created working directory (muter_tmp) in:\n\n\(currentDirectoryPath)")

    printMessage("Discovering source code in:\n\n\(currentDirectoryPath)")
    let sourceFilePaths = discoverSourceFiles(inDirectoryAt: currentDirectoryPath, excludingPathsIn: configuration.excludeList)
    let swapFilePathsByOriginalPath = swapFilePaths(forFilesAt: sourceFilePaths, using: workingDirectoryPath)
    printDiscoveryMessage(for: sourceFilePaths)

    printMessage("Discovering applicable Mutation Operators in:\n\n\(currentDirectoryPath)")
    let mutationOperators = discoverMutationOperators(inFilesAt: sourceFilePaths)

    guard mutationOperators.count >= 1 else {
        printMessage("""
        Muter wasn't able to discover any code it could mutation test.

        This is likely caused by misconfiguring Muter, usually by excluding a directory that contains your code.

        If you feel this is a bug, or want help figuring out what could be happening, please open an issue at
        https://github.com/SeanROlszewski/muter/issues

        """)
        exit(1)
    }

    printDiscoveryMessage(for: mutationOperators)

    FileManager.default.changeCurrentDirectoryPath(currentDirectoryPath)

    printMessage("Beginning mutation testing")
    let testingDelegate = MutationTestingDelegate(configuration: configuration, swapFilePathsByOriginalPath: swapFilePathsByOriginalPath)
    let testReport = performMutationTesting(using: mutationOperators, delegate: testingDelegate)

    printMessage(testReport?.description ?? "")
    return testReport
}

public func save(_ report: MuterTestReport?, to currentDirectoryUrl: URL) {
    let fileName = currentDirectoryUrl.appendingPathComponent("muterReport.json")
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted

    do {
        let encodedReport = try encoder.encode(report)
        try encodedReport.write(to: fileName)
    } catch {
        print("""
            Muter was unable to write its report to your disk at path \(fileName.absoluteString).

            If you can reproduce this, please consider filing a bug
            at https://github.com/SeanROlszewski/muter

            Please include the following in the bug report:
            *********************
            \(error)
            """)
    }
}

// MARK - Setup Handler

@available(OSX 10.13, *)
public func setupMuter(using manager: FileManager, and directory: String) throws {
    let configuration = MuterConfiguration(executable: "absolute path to the executable that runs your tests",
                                           arguments: ["an argument the test runner needs", "another argument the test runner needs"],
                                           excludeList: [])
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try! encoder.encode(configuration)

    manager.createFile(atPath: "\(directory)/muter.conf.json",
        contents: data,
        attributes: nil)
}
