import Foundation

public protocol RunCommandIODelegate  {
    func loadConfiguration() -> MuterConfiguration?
    func backupProject(in directory: String)
    func executeTesting(using configuration: MuterConfiguration)
}

@available(OSX 10.13, *)
public class RunCommandDelegate: RunCommandIODelegate {

    private let fileManager: FileSystemManager
    private let notificationCenter: NotificationCenter

    public var temporaryDirectoryURL: String?

    public init(fileManager: FileSystemManager = FileManager.default, notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.fileManager = fileManager
        self.notificationCenter = notificationCenter
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

            notificationCenter.post(name: .projectCopyStarted, object: nil)
            let destinationPath = destinationDirectoryPath(in: temporaryDirectory, withProjectName: URL(fileURLWithPath: directory).lastPathComponent)
            try fileManager.copyItem(atPath: directory, toPath: destinationPath)
            temporaryDirectoryURL = destinationPath

            notificationCenter.post(name: .projectCopyFinished, object: nil)

        } catch {
            notificationCenter.post(name: .projectCopyFailed, object: error)
        }
    }

    private func destinationDirectoryPath(in temporaryDirectory: URL, withProjectName name: String) -> String {
        let destination = temporaryDirectory.appendingPathComponent(name, isDirectory: true)
        return destination.path
    }

    public func executeTesting(using configuration: MuterConfiguration) {

        let workingDirectoryPath = createWorkingDirectory(in: temporaryDirectoryURL!)
        notificationCenter.post(name: .sourceFileDiscoveryStarted, object: temporaryDirectoryURL!)

        let sourceFilePaths = discoverSourceFiles(inDirectoryAt: temporaryDirectoryURL!, excludingPathsIn: configuration.excludeList)
        let swapFilePathsByOriginalPath = swapFilePaths(forFilesAt: sourceFilePaths, using: workingDirectoryPath)
        notificationCenter.post(name: .sourceFileDiscoveryFinished, object: sourceFilePaths)

        notificationCenter.post(name: .mutationOperatorDiscoveryStarted, object: temporaryDirectoryURL!)
        let mutationOperators = discoverMutationOperators(inFilesAt: sourceFilePaths)
        guard mutationOperators.count >= 1 else {
            notificationCenter.post(name: .noMutationOperatorsDiscovered, object: nil)
            return
        }
        notificationCenter.post(name: .mutationOperatorDiscoveryFinished, object: mutationOperators)

        FileManager.default.changeCurrentDirectoryPath(temporaryDirectoryURL!)

        notificationCenter.post(name: .mutationTestingStarted, object: nil)

        let testingDelegate = MutationTestingDelegate(configuration: configuration, swapFilePathsByOriginalPath: swapFilePathsByOriginalPath)
        let report = performMutationTesting(using: mutationOperators, delegate: testingDelegate)

        notificationCenter.post(name: .mutationTestingFinished, object: report)
    }
}
