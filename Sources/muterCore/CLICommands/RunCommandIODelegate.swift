import Foundation

public protocol RunCommandIODelegate  {
    func loadConfiguration() -> MuterConfiguration?
    func backupProject(in directory: String)
    func executeTesting(using configuration: MuterConfiguration) -> MuterTestReport?
}

@available(OSX 10.13, *)
public class RunCommandDelegate: RunCommandIODelegate {

    private let fileManager: FileSystemManager
    public var temporaryDirectoryURL: String?

    public init(fileManager: FileSystemManager = FileManager.default) {
        self.fileManager = fileManager
    }

    public func loadConfiguration() -> MuterConfiguration? {
        let configurationPath = fileManager.currentDirectoryPath + "/muter.conf.json"

        guard let configurationData = fileManager.contents(atPath: configurationPath),
            let configuration = try? JSONDecoder().decode(MuterConfiguration.self, from: configurationData) else {
                return nil
        }

        return configuration
    }

    public func backupProject(in directory: String) {
        do {
            let temporaryDirectory = try fileManager.url(
                for: .itemReplacementDirectory,
                in: .userDomainMask,
                appropriateFor: URL(fileURLWithPath: directory), // The appropriateFor parameter is used to make sure the temp directory is on the same volume as the passed parameter.
                create: true // the create parameter is ignored when passing .itemReplacementDirectory
            )

            let destinationPath = destinationDirectoryPath(in: temporaryDirectory, withProjectName: URL(fileURLWithPath: directory).lastPathComponent)
            print("Copying your project for mutation testing")
            try fileManager.copyItem(atPath: directory, toPath: destinationPath)
            temporaryDirectoryURL = destinationPath

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

    public func executeTesting(using configuration: MuterConfiguration) -> MuterTestReport? {
        let workingDirectoryPath = createWorkingDirectory(in: temporaryDirectoryURL!)
        printMessage("Created working directory (muter_tmp) in:\n\n\(temporaryDirectoryURL!)")

        printMessage("Discovering source code in:\n\n\(temporaryDirectoryURL!)")
        let sourceFilePaths = discoverSourceFiles(inDirectoryAt: temporaryDirectoryURL!, excludingPathsIn: configuration.excludeList)
        let swapFilePathsByOriginalPath = swapFilePaths(forFilesAt: sourceFilePaths, using: workingDirectoryPath)
        printDiscoveryMessage(for: sourceFilePaths)

        printMessage("Discovering applicable Mutation Operators in:\n\n\(temporaryDirectoryURL!)")
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

        FileManager.default.changeCurrentDirectoryPath(temporaryDirectoryURL!)

        printMessage("Beginning mutation testing")
        let testingDelegate = MutationTestingDelegate(configuration: configuration, swapFilePathsByOriginalPath: swapFilePathsByOriginalPath)
        guard let testReport = performMutationTesting(using: mutationOperators, delegate: testingDelegate) else {
            printMessage("")
            return nil
        }

        printMessage(textReporter(report: testReport))
        return testReport
    }
}
