import Darwin.C
import Foundation
import Progress
import Rainbow
import SwiftSyntax

extension Notification.Name {
    static let muterLaunched = Notification.Name("muterLaunched")

    static let updateCheckStarted = Notification.Name("updateCheckStarted")
    static let updateCheckFinished = Notification.Name("updateCheckFinished")

    static let projectCopyStarted = Notification.Name("projectCopyStarted")
    static let projectCopyFinished = Notification.Name("projectCopyFinished")

    static let projectCoverageDiscoveryStarted = Notification.Name("projectCoverageDiscoveryStarted")
    static let projectCoverageDiscoveryFinished = Notification.Name("projectCoverageDiscoveryFinished")

    static let sourceFileDiscoveryStarted = Notification.Name("sourceFileDiscoveryStarted")
    static let sourceFileDiscoveryFinished = Notification.Name("sourceFileDiscoveryFinished")

    static let mutationsDiscoveryStarted = Notification.Name("mutationsDiscoveryStarted")
    static let mutationsDiscoveryFinished = Notification.Name("mutationsDiscoveryFinished")

    static let mutationTestingStarted = Notification.Name("mutationTestingStarted")
    static let mutationTestingFinished = Notification.Name("mutationTestingFinished")

    static let newMutationTestOutcomeAvailable = Notification.Name("newMutationTestOutcomeAvailable")
    static let newTestLogAvailable = Notification.Name("newTestLogAvailable")

    static let configurationFileCreated = Notification.Name("configurationFileCreated")
}

final class RunCommandObserver {
    @Dependency(\.logger)
    private var logger: Logger
    @Dependency(\.fileManager)
    private var fileManager: FileSystemManager
    @Dependency(\.flushStandardOut)
    private var flushStdOut: () -> Void
    @Dependency(\.notificationCenter)
    private var notificationCenter: NotificationCenter

    private var numberOfMutationPoints: Int = 0
    private var loggingDirectory: String = ""
    private let runOptions: RunOptions

    private var notificationHandlerMappings: [(name: Notification.Name, handler: (Notification) -> Void)] {
        [
            (name: .muterLaunched, handler: handleMuterLaunched),

            (name: .updateCheckStarted, handler: handleUpdateCheckStarted),
            (name: .updateCheckFinished, handler: handleUpdateCheckFinished),

            (name: .projectCopyStarted, handler: handleProjectCopyStarted),
            (name: .projectCopyFinished, handler: handleProjectCopyFinished),

            (name: .projectCoverageDiscoveryStarted, handler: handleProjectCoverageDiscoveryStarted),
            (name: .projectCoverageDiscoveryFinished, handler: handleProjectCoverageDiscoveryFinished),

            (name: .sourceFileDiscoveryStarted, handler: handleSourceFileDiscoveryStarted),
            (name: .sourceFileDiscoveryFinished, handler: handleSourceFileDiscoveryFinished),

            (name: .mutationsDiscoveryStarted, handler: handleMutationsDiscoveryStarted),
            (name: .mutationsDiscoveryFinished, handler: handleMutationsDiscoveryFinished),

            (name: .mutationTestingStarted, handler: handleMutationTestingStarted),

            (name: .newMutationTestOutcomeAvailable, handler: handleNewMutationTestOutcomeAvailable),
            (name: .newTestLogAvailable, handler: handleNewTestLogAvailable),

            (name: .mutationTestingFinished, handler: handleMutationTestingFinished),
        ]
    }

    init(
        runOptions: RunOptions
    ) {
        self.runOptions = runOptions
        loggingDirectory = createLoggingDirectory(
            in: fileManager.currentDirectoryPath,
            fileManager: fileManager
        )

        for (name, handler) in notificationHandlerMappings {
            notificationCenter.addObserver(
                forName: name,
                object: nil,
                queue: nil,
                using: handler
            )
        }
    }

    deinit {
        notificationCenter.removeObserver(self)
    }
}

extension RunCommandObserver {
    func handleMuterLaunched(notification: Notification) {
        logger.launched()
    }

    func handleUpdateCheckStarted(notification: Notification) {
        logger.updateCheckStarted()
    }

    func handleUpdateCheckFinished(notification: Notification) {
        logger.updateCheckFinished(newVersion: notification.object as? String)
    }

    func handleProjectCopyStarted(notification: Notification) {
        logger.projectCopyStarted()
    }

    func handleProjectCopyFinished(notification: Notification) {
        logger.projectCopyFinished(destinationPath: notification.object as! String)
    }

    func handleProjectCoverageDiscoveryStarted(notification: Notification) {
        logger.projectCoverageDiscoveryStarted()
    }

    func handleProjectCoverageDiscoveryFinished(notification: Notification) {
        (notification.object as? Bool).map {
            logger.projectCoverageDiscoveryFinished(success: $0)
        }
    }

    func handleSourceFileDiscoveryStarted(notification: Notification) {
        logger.sourceFileDiscoveryStarted()
    }

    func handleSourceFileDiscoveryFinished(notification: Notification) {
        logger.sourceFileDiscoveryFinished(sourceFileCandidates: notification.object as! [String])
    }

    func handleMutationsDiscoveryStarted(notification: Notification) {
        logger.mutationsDiscoveryStarted()
    }

    func handleMutationsDiscoveryFinished(notification: Notification) {
        logger.mutationsDiscoveryFinished(mutations: notification.object as! [SchemataMutationMapping])
    }

    func handleMutationTestingStarted(notification: Notification) {
        logger.mutationTestingStarted()
    }

    func handleNewMutationTestOutcomeAvailable(notification: Notification) {
        runOptions.reportOptions.reporter.newMutationTestOutcomeAvailable(
            outcomeWithFlush: MutationOutcomeWithFlush(
                mutation: notification.object as! MutationTestOutcome.Mutation,
                fflush: flushStdOut
            )
        )
    }

    func handleNewTestLogAvailable(notification: Notification) {
        let mutationTestLog = notification.object as! MutationTestLog

        logger.newMutationTestLogAvailable(mutationTestLog: mutationTestLog)

        _ = fileManager.createFile(
            atPath: "\(loggingDirectory)/\(logFileName(from: mutationTestLog.mutationPoint))",
            contents: mutationTestLog.testLog.data(using: .utf8),
            attributes: nil
        )
    }

    func logFileName(from mutationPoint: MutationPoint?) -> String {
        guard let mutationPoint else {
            return "baseline run.log"
        }

        return "\(mutationPoint.mutationOperatorId.rawValue) @ \(mutationPoint.fileName)-\(mutationPoint.position.line)-\(mutationPoint.position.column).log"
    }

    func handleMutationTestingFinished(notification: Notification) {
        Logger.print("Muter finished running!")
        Logger.print("\n")

        let reporter = runOptions.reportOptions.reporter
        let reportPath = runOptions.reportOptions.path ?? ""
        let report = reporter.report(from: notification.object as! MutationTestOutcome)

        guard !reportPath.isEmpty else {
            return Logger.print(
                """
                Muter's report

                \(report)
                """
            )
        }

        if fileManager.fileExists(atPath: reportPath) {
            try? fileManager.removeItem(atPath: reportPath)
        }

        let didSave = fileManager.createFile(
            atPath: reportPath,
            contents: report.data(using: .utf8),
            attributes: nil
        )

        if didSave {
            Logger.print("Report generated: \(reportPath.bold)")
        } else {
            Logger.print(report)
            Logger.print("\n")
            Logger.print("Could not save report!")
        }
    }
}
