import Foundation

extension Notification.Name {
    static let projectCopyStarted = Notification.Name("projectCopyStarted")
    static let projectCopyFinished = Notification.Name("projectCopyFinished")
    static let projectCopyFailed = Notification.Name("projectCopyFailed")

    static let workingDirectoryCreated = Notification.Name("workingDirectoryCreated")

    static let sourceFileDiscoveryStarted = Notification.Name("sourceFileDiscoveryStarted")
    static let sourceFileDiscoveryFinished = Notification.Name("sourceFileDiscoveryFinished")

    static let mutationOperatorDiscoveryStarted = Notification.Name("mutationOperatorDiscoveryStarted")
    static let mutationOperatorDiscoveryFinished = Notification.Name("mutationOperatorDiscoveryFinished")
    static let noMutationOperatorsDiscovered = Notification.Name("noMutationOperatorsDiscovered")

    static let mutationTestingStarted = Notification.Name("mutationTestingStarted")
    static let mutationTestingFinished = Notification.Name("mutationTestingFinished")
    static let mutationTestingAborted = Notification.Name("mutationTestingAborted")

    static let appliedNewMutationOperator = Notification.Name("applyingNewMutationOperator")

    static let configurationFileCreated = Notification.Name("configurationFileCreated")
}

class StdoutObserver {
    private let notificationCenter: NotificationCenter = .default
    private let reporter: Reporter

    init(reporter: @escaping Reporter) {
        self.reporter = reporter

        notificationCenter.addObserver(forName: .projectCopyStarted, object: nil, queue: nil, using: handleProjectCopyStarted)
        notificationCenter.addObserver(forName: .projectCopyFinished, object: nil, queue: nil, using: handleProjectCopyFinished)
        notificationCenter.addObserver(forName: .projectCopyFailed, object: nil, queue: nil, using: handleProjectCopyFailed)

        notificationCenter.addObserver(forName: .sourceFileDiscoveryStarted, object: nil, queue: nil, using: handleSourceFileDiscoveryStarted)
        notificationCenter.addObserver(forName: .sourceFileDiscoveryFinished, object: nil, queue: nil, using: handleSourceFileDiscoveryFinished)

        notificationCenter.addObserver(forName: .mutationOperatorDiscoveryStarted, object: nil, queue: nil, using: handleMutationOperatorDiscoveryStarted)
        notificationCenter.addObserver(forName: .mutationOperatorDiscoveryFinished, object: nil, queue: nil, using: handleMutationOperatorDiscoveryFinished)
        notificationCenter.addObserver(forName: .noMutationOperatorsDiscovered, object: nil, queue: nil, using: handleNoMutationOperatorsDiscovered)

        notificationCenter.addObserver(forName: .mutationTestingStarted, object: nil, queue: nil, using: handleMutationTestingStarted)
                notificationCenter.addObserver(forName: .appliedNewMutationOperator, object: nil, queue: nil, using: handleAppliedNewMutationOperator)
        notificationCenter.addObserver(forName: .mutationTestingFinished, object: nil, queue: nil, using: handleMutationTestingFinished)
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

}

private extension StdoutObserver {

    func handleProjectCopyStarted(notification: Notification) {
        print("Copying your project to a temporary directory for testing")
    }

    func handleProjectCopyFinished(notification: Notification) {
        print("Finished copying your project to a temporary directory for testing")
    }

    func handleProjectCopyFailed(notification: Notification) {
        fatalError("""
            Muter was unable to create a temporary directory,
            or was unable to copy your project, and cannot continue.

            If you can reproduce this, please consider filing a bug
            at https://github.com/SeanROlszewski/muter

            Please include the following in the bug report:
            *********************
            FileManager error: \(String(describing: notification.object))
            """)
    }

    func handleSourceFileDiscoveryStarted(notification: Notification) {
        printMessage("Discovering source code in:\n\n\(notification.object as! String)")
    }

    func handleSourceFileDiscoveryFinished(notification: Notification) {
        let discoveredFilePaths = notification.object as! [String]
        let filePaths = discoveredFilePaths.joined(separator: "\n")
        printMessage("Discovered \(discoveredFilePaths.count) Swift files:\n\n\(filePaths)")
    }

    func handleMutationOperatorDiscoveryStarted(notification: Notification) {
        print("Discovering applicable Mutation Operators in:\n\n\(notification.object as! String)")
    }

    func handleMutationOperatorDiscoveryFinished(notification: Notification) {
        let discoveredMutationOperators = notification.object as! [MutationOperator]
        
        printMessage("Discovered \(discoveredMutationOperators.count) mutants to introduce:\n")
        
        for (index, `operator`) in discoveredMutationOperators.enumerated() {
            let listPosition = "\(index+1))"
            let fileName = URL(fileURLWithPath: `operator`.filePath).lastPathComponent
            print("\(listPosition) \(fileName)")
        }
    }

    func handleNoMutationOperatorsDiscovered(notification: Notification) {
        printMessage("""

                    Muter wasn't able to discover any code it could mutation test.

                    This is likely caused by misconfiguring Muter, usually by excluding a directory that contains your code.

                    If you feel this is a bug, or want help figuring out what could be happening, please open an issue at
                    https://github.com/SeanROlszewski/muter/issues

        """)
        exit(1)
    }
    
    func handleMutationTestingStarted(notification: Notification) {
        printMessage("Mutation testing will now begin.\nRunning your test suite to determine a baseline for mutation testing")
    }
    
    func handleAppliedNewMutationOperator(notification: Notification) {
        let values = notification.object as! (fileName: String, remainingOperatorsCount: Int)
        
        print("Testing mutation operator in \(values.fileName)")
        print("There are \(values.remainingOperatorsCount) left to apply")
    }
    
    func handleMutationTestingFinished(notification: Notification) {
        let report = notification.object as! MuterTestReport
        print(reporter(report))
    }
}
