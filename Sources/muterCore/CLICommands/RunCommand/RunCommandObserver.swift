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
    private let reporter: Reporter
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
    
    init(reporter: Reporter, fileManager: FileSystemManager, flushHandler: @escaping () -> Void) {
        self.reporter = reporter
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
        reporter.launched()
    }
    
    func handleProjectCopyStarted(notification: Notification) {
        reporter.projectCopyStarted()
    }

    func handleProjectCopyFinished(notification: Notification) {
        reporter.projectCopyFinished(destinationPath: notification.object as! String)
    }
    
    func handleProjectCoverageDiscoveryStarted(notification: Notification) {
        reporter.projectCoverageDiscoveryStarted()
    }

    func handleProjectCoverageDiscoveryFinished(notification: Notification) {
        (notification.object as? Bool).map {
            reporter.projectCoverageDiscoveryFinished(success: $0)
        }
    }

    func handleSourceFileDiscoveryStarted(notification: Notification) {
        reporter.sourceFileDiscoveryStarted()
    }

    func handleSourceFileDiscoveryFinished(notification: Notification) {
        reporter.sourceFileDiscoveryFinished(sourceFileCandidates: notification.object as! [String])
    }

    func handleMutationPointDiscoveryStarted(notification: Notification) {
        reporter.mutationPointDiscoveryStarted()
    }

    func handleMutationPointDiscoveryFinished(notification: Notification) {
        reporter.mutationPointDiscoveryFinished(mutationPoints: notification.object as! [MutationPoint])
    }

    func handleMutationTestingStarted(notification: Notification) {
        reporter.mutationTestingStarted()
    }

    func handleNewMutationTestOutcomeAvailable(notification: Notification) {
        reporter.newMutationTestOutcomeAvailable(
            outcomeWithFlush: MutationOutcomeWithFlush(
                mutation: notification.object as! MutationTestOutcome.Mutation,
                fflush: flushStdOut
            )
        )
    }

    func handleNewTestLogAvailable(notification: Notification) {
        let mutationTestLog = notification.object as! MutationTestLog

        reporter.newMutationTestLogAvailable(mutationTestLog: mutationTestLog)
        
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
        reporter.mutationTestingFinished(
            mutationTestOutcome: notification.object as! MutationTestOutcome
        )
    }
}
