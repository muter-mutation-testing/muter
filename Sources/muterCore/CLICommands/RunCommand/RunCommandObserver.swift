import Foundation
import Darwin.C
import SwiftSyntax

extension Notification.Name {
    static let muterLaunched = Notification.Name("muterLaunched")
    static let projectCopyStarted = Notification.Name("projectCopyStarted")
    static let projectCopyFinished = Notification.Name("projectCopyFinished")

    static let workingDirectoryCreated = Notification.Name("workingDirectoryCreated")

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

class RunCommandObserver {
    private let reporter: Reporter
    private let fileManager: FileSystemManager
    private let loggingDirectory: String
    private let flushStdOut: () -> Void
    private let notificationCenter: NotificationCenter = .default
    private var notificationHandlerMappings: [(name: Notification.Name, handler: (Notification) -> Void)] {
       return [
            (name: .muterLaunched, handler: handleMuterLaunched),
            
            (name: .projectCopyStarted, handler: handleProjectCopyStarted),
            (name: .projectCopyFinished, handler: handleProjectCopyFinished),
            
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
        if reporter == .plainText {
            printHeader()
        }
    }
    
    func handleProjectCopyStarted(notification: Notification) {
        if reporter == .plainText {
            print("Copying your project to a temporary directory for testing")
        }
    }

    func handleProjectCopyFinished(notification: Notification) {
        if reporter == .plainText {
            print("Finished copying your project to a temporary directory for testing")
        }
    }

    func handleSourceFileDiscoveryStarted(notification: Notification) {
        if reporter == .plainText {
            let url = notification.object as! URL
            printMessage("Discovering source code in:\n\n\(url.path)")
        }
    }

    func handleSourceFileDiscoveryFinished(notification: Notification) {
        if reporter == .plainText {
            let discoveredFilePaths = notification.object as! [String]
            let filePaths = discoveredFilePaths.joined(separator: "\n")
            printMessage("Discovered \(discoveredFilePaths.count) Swift files:\n\n\(filePaths)")
        }
    }

    func handleMutationPointDiscoveryStarted(notification: Notification) {
        if reporter == .plainText {
            let url = notification.object as! URL
            print("Discovering mutants to insert in project at path:\n\n\(url.path)")
        }
    }

    func handleMutationPointDiscoveryFinished(notification: Notification) {
        if reporter == .plainText {
            let discoveredMutationPoints = notification.object as! [MutationPoint]

            printMessage("Discovered \(discoveredMutationPoints.count) mutants to introduce:\n")

            for (index, mutationPoint) in discoveredMutationPoints.enumerated() {
                let listPosition = "\(index+1))"
                print("\(listPosition) \(mutationPoint.fileName)")
            }
        }
    }

    func handleMutationTestingStarted(notification: Notification) {
        if reporter == .plainText {
            printMessage("""
            Mutation testing will now begin.
            Running your test suite to determine a baseline for mutation testing
            """)
        }
    }

    func handleNewMutationTestOutcomeAvailable(notification: Notification) {
        let values = notification.object as! (outcome: MutationTestOutcome, remainingOperatorsCount: Int)
        
        if reporter == .plainText {
            print("""
            Testing mutation operator in \(values.outcome.mutationPoint.fileName)
            There are \(values.remainingOperatorsCount) left to apply
            """)
        } else if reporter == .xcode {
            print(reporter.generateReport(from: [values.outcome]))
            flushStdOut()
        }
    }

    func handleNewTestLogAvailable(notification: Notification) {
        guard let (mutationPoint, testLog, estimatedTimeRemaining) = notification.object as? (MutationPoint?, String, TimeInterval) else {
            return
        }
        
        if [.plainText, .xcode].contains(reporter) {
            let numberOfMinutes = Int(ceil(estimatedTimeRemaining / 60))
            print("""
            Muter will finish in about \(numberOfMinutes) minutes
            """)
        }
        
        _ = fileManager.createFile(
            atPath: "\(loggingDirectory)/\(logFileName(from: mutationPoint))",
            contents: testLog.data(using: .utf8),
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
        if reporter != .xcode { // xcode reports are generated in real-time, so don't report them once mutation testing has finished
            let outcomes = notification.object as! [MutationTestOutcome]
            print(reporter.generateReport(from: outcomes))
        }
    }
}



