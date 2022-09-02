import Foundation
import Darwin.C
import SwiftSyntax
import Progress
import Rainbow

extension Notification.Name {
    static let muterLaunched = Notification.Name("muterLaunched")
    static let projectCopyStarted = Notification.Name("projectCopyStarted")
    static let projectCopyFinished = Notification.Name("projectCopyFinished")
    
    static let projectCoverageDiscoveryStarted = Notification.Name("projectCoverageDiscoveryStarted")
    static let projectCoverageDiscoveryFinished = Notification.Name("projectCoverageDiscoveryFinished")

    static let sourceFileDiscoveryStarted = Notification.Name("sourceFileDiscoveryStarted")
    static let sourceFileDiscoveryFinished = Notification.Name("sourceFileDiscoveryFinished")

    static let mutationPointDiscoveryStarted = Notification.Name("mutationPointDiscoveryStarted")
    static let mutationPointDiscoveryFinished = Notification.Name("mutationPointDiscoveryFinished")

    static let mutationTestingStarted = Notification.Name("mutationTestingStarted")
    static let mutationTestingFinished = Notification.Name("mutationTestingFinished")

    static let newMutationTestOutcomeAvailable = Notification.Name("newMutationTestOutcomeAvailable")
    static let newTestLogAvailable = Notification.Name("newTestLogAvailable")

    static let configurationFileCreated = Notification.Name("configurationFileCreated")
}

func flushStdOut() {
    fflush(stdout)
}

final class RunCommandObserver {
    private let options: RunOptions
    private let logger: Logger
    private let fileManager: FileSystemManager
    private let loggingDirectory: String
    private let flushStdOut: () -> Void
    private var numberOfMutationPoints: Int!
    private let notificationCenter: NotificationCenter = .default
    private var notificationHandlerMappings: [(name: Notification.Name, handler: (Notification) -> Void)] {
        return [
            (name: .muterLaunched, handler: handleMuterLaunched),
            
            (name: .projectCopyStarted, handler: handleProjectCopyStarted),
            (name: .projectCopyFinished, handler: handleProjectCopyFinished),
            
            (name: .projectCoverageDiscoveryStarted, handler: handleProjectCoverageDiscoveryStarted),
            (name: .projectCoverageDiscoveryFinished, handler: handleProjectCoverageDiscoveryFinished),
            
            (name: .sourceFileDiscoveryStarted, handler: handleSourceFileDiscoveryStarted),
            (name: .sourceFileDiscoveryFinished, handler: handleSourceFileDiscoveryFinished),
            
            (name: .mutationPointDiscoveryStarted, handler: handleMutationPointDiscoveryStarted),
            (name: .mutationPointDiscoveryFinished, handler: handleMutationPointDiscoveryFinished),
            
            (name: .mutationTestingStarted, handler: handleMutationTestingStarted),
            
            (name: .newMutationTestOutcomeAvailable, handler: handleNewMutationTestOutcomeAvailable),
            (name: .newTestLogAvailable, handler: handleNewTestLogAvailable),
            
            (name: .mutationTestingFinished, handler: handleMutationTestingFinished),
        ]
    }
    
    init(
        options: RunOptions,
        fileManager: FileSystemManager,
        flushHandler: @escaping () -> Void
    ) {
        self.options = options
        self.logger = options.logger
        self.fileManager = fileManager
        self.flushStdOut = flushHandler
        self.loggingDirectory = createLoggingDirectory(in: fileManager.currentDirectoryPath, fileManager: fileManager)

        for (name, handler) in notificationHandlerMappings {
            notificationCenter.addObserver(forName: name, object: nil, queue: nil, using: handler)
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

    func handleMutationPointDiscoveryStarted(notification: Notification) {
        logger.mutationPointDiscoveryStarted()
    }

    func handleMutationPointDiscoveryFinished(notification: Notification) {
        logger.mutationPointDiscoveryFinished(mutationPoints: notification.object as! [MutationPoint])
    }

    func handleMutationTestingStarted(notification: Notification) {
        logger.mutationTestingStarted()
    }

    func handleNewMutationTestOutcomeAvailable(notification: Notification) {
        options.reportOptions.reporter.newMutationTestOutcomeAvailable(
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
        guard let mutationPoint = mutationPoint else {
            return "baseline run.log"
        }
                
        return "\(mutationPoint.mutationOperatorId.rawValue) @ \(mutationPoint.fileName)-\(mutationPoint.position.line)-\(mutationPoint.position.column).log"
    }

    func handleMutationTestingFinished(notification: Notification) {
        Logger.print("Muter finished running!")
        Logger.print("\n\n")

        let reporter = options.reportOptions.reporter
        let reportPath = options.reportOptions.path ?? ""
        let report = reporter.report(from: notification.object as! MutationTestOutcome)
        
        guard !reportPath.isEmpty else {
            return Logger.print(
                """
                Muter's report
                
                \(report)
                """
            )
        }

        let didSave = fileManager.createFile(
            atPath: reportPath,
            contents: report.data(using: .utf8),
            attributes: nil
        )
        
        if didSave {
            Logger.print("Report generated: \(reportPath)")
        } else {
            Logger.print(report)
            Logger.print("\n\n")
            Logger.print("Could not save report!")
        }
    }
}
