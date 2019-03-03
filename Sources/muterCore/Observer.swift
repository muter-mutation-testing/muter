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
        
        notificationCenter.addObserver(forName: .projectCopyStarted, object: nil, queue: nil, using: handle)
        notificationCenter.addObserver(forName: .projectCopyFinished, object: nil, queue: nil, using: handle)
        notificationCenter.addObserver(forName: .projectCopyFailed, object: nil, queue: nil, using: handle)
        notificationCenter.addObserver(forName: .workingDirectoryCreated, object: nil, queue: nil, using: handle)
        notificationCenter.addObserver(forName: .sourceFileDiscoveryStarted, object: nil, queue: nil, using: handle)
        notificationCenter.addObserver(forName: .sourceFileDiscoveryFinished, object: nil, queue: nil, using: handle)
        notificationCenter.addObserver(forName: .mutationOperatorDiscoveryStarted, object: nil, queue: nil, using: handle)
        notificationCenter.addObserver(forName: .mutationOperatorDiscoveryFinished, object: nil, queue: nil, using: handle)
        notificationCenter.addObserver(forName: .noMutationOperatorsDiscovered, object: nil, queue: nil, using: handle)
        notificationCenter.addObserver(forName: .mutationTestingStarted, object: nil, queue: nil, using: handle)
        notificationCenter.addObserver(forName: .mutationTestingFinished, object: nil, queue: nil, using: handle)
    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }
    
    private func handle(notification: Notification) {
        print("received notification \(notification)")
    }
}
