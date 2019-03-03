import Foundation

public protocol RunCommandIODelegate  {
    func loadConfiguration() -> MuterConfiguration?
    func backupProject(in directory: String)
    func executeTesting(using configuration: MuterConfiguration) -> MuterTestReport?
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

            let destinationPath = destinationDirectoryPath(in: temporaryDirectory, withProjectName: URL(fileURLWithPath: directory).lastPathComponent)
            try fileManager.copyItem(atPath: directory, toPath: destinationPath)
            temporaryDirectoryURL = destinationPath
            notificationCenter.post(name: .projectCopyFinished, object: nil)

        } catch {
//            fatalError("""
//                Muter was unable to create a temporary directory,
//                or was unable to copy your project, and cannot continue.
//
//                If you can reproduce this, please consider filing a bug
//                at https://github.com/SeanROlszewski/muter
//
//                Please include the following in the bug report:
//                *********************
//                FileManager error: \(error)
//                """)
            notificationCenter.post(name: .projectCopyFailed, object: nil)

        }
    }

    private func destinationDirectoryPath(in temporaryDirectory: URL, withProjectName name: String) -> String {
        let destination = temporaryDirectory.appendingPathComponent(name, isDirectory: true)
        return destination.path
    }

    public func executeTesting(using configuration: MuterConfiguration) -> MuterTestReport? {
        
        let workingDirectoryPath = createWorkingDirectory(in: temporaryDirectoryURL!)
//        printMessage("Created working directory (muter_tmp) in:\n\n\(temporaryDirectoryURL!)")
        notificationCenter.post(name: .workingDirectoryCreated, object: nil)


//        printMessage("Discovering source code in:\n\n\(temporaryDirectoryURL!)")
        notificationCenter.post(name: .sourceFileDiscoveryStarted, object: nil)

        let sourceFilePaths = discoverSourceFiles(inDirectoryAt: temporaryDirectoryURL!, excludingPathsIn: configuration.excludeList)
        let swapFilePathsByOriginalPath = swapFilePaths(forFilesAt: sourceFilePaths, using: workingDirectoryPath)
        notificationCenter.post(name: .sourceFileDiscoveryFinished, object: nil)

//        printDiscoveryMessage(for: sourceFilePaths)

//        printMessage("Discovering applicable Mutation Operators in:\n\n\(temporaryDirectoryURL!)")
        notificationCenter.post(name: .mutationOperatorDiscoveryStarted, object: nil)

        let mutationOperators = discoverMutationOperators(inFilesAt: sourceFilePaths)

        guard mutationOperators.count >= 1 else {
//            printMessage("""
//        Muter wasn't able to discover any code it could mutation test.
//
//        This is likely caused by misconfiguring Muter, usually by excluding a directory that contains your code.
//
//        If you feel this is a bug, or want help figuring out what could be happening, please open an issue at
//        https://github.com/SeanROlszewski/muter/issues
//
//        """)
//            exit(1)
            notificationCenter.post(name: .noMutationOperatorsDiscovered, object: nil)
            return nil
        }

//        printDiscoveryMessage(for: mutationOperators)
        notificationCenter.post(name: .mutationOperatorDiscoveryFinished, object: nil)


        FileManager.default.changeCurrentDirectoryPath(temporaryDirectoryURL!)

        notificationCenter.post(name: .mutationTestingStarted, object: nil)

        let testingDelegate = MutationTestingDelegate(configuration: configuration, swapFilePathsByOriginalPath: swapFilePathsByOriginalPath)
        let report = performMutationTesting(using: mutationOperators, delegate: testingDelegate)
        
        notificationCenter.post(name: .mutationTestingFinished, object: nil)
        return report
    }
}
