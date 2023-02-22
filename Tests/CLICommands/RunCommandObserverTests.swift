import XCTest

@testable import muterCore

final class RunCommandObserverTests: MuterTestCase {
    private var options = RunOptions.make()
    
    private lazy var sut = RunCommandObserver(runOptions: options)
    
    override func setUp() {
        super.setUp()
        
        fileManager.currentDirectoryPathToReturn = "/"
    }
    
    func test_flushesStdoutWhenUsingAnXcodeReporter() {
        options = .make(reportFormat: .xcode)

        sut.handleNewMutationTestOutcomeAvailable(notification: .make())
        
        XCTAssertTrue(flushStandardOut.flushHandlerWasCalled)
    }
    
    func test_doesntFlushStdoutWhenUsingAJsonReporter() {
        options = .make(reportFormat: .json)

        sut.handleNewMutationTestOutcomeAvailable(notification: .make())
        
        XCTAssertFalse(flushStandardOut.flushHandlerWasCalled)
    }
    
    func test_doesntFlushStdoutWhenUsingAPlainTextReporter() {
        options = .make(reportFormat: .plain)

        sut.handleNewMutationTestOutcomeAvailable(notification: .make())
        
        XCTAssertFalse(flushStandardOut.flushHandlerWasCalled)
    }
    
    func test_logFileNameUsingAPlainTextReporter() {
        options = .make(reportFormat: .plain)
        
        XCTAssertEqual(sut.logFileName(from: nil), "baseline run.log")
    }
    
    func test_logFileNameUsingAXcodeReporter() {
        options = .make(reportFormat: .xcode)
        
        let mutationPoint1 = MutationPoint(
            mutationOperatorId: .ror,
            filePath: "~/user/file.swift",
            position: .firstPosition
        )

        let mutationPoint2 = MutationPoint(
            mutationOperatorId: .removeSideEffects,
            filePath: "~/user/file2.swift",
            position: MutationPosition(utf8Offset: 2, line: 5, column: 6)
        )
        
        XCTAssertEqual(
            sut.logFileName(from: mutationPoint1),
            "RelationalOperatorReplacement @ file.swift-0-0.log"
        )

        XCTAssertEqual(
            sut.logFileName(from: mutationPoint2),
            "RemoveSideEffects @ file2.swift-5-6.log"
        )
    }
}

private extension Notification {
    static func make() -> Notification {
        Notification(
            name: .newMutationTestOutcomeAvailable,
            object: MutationTestOutcome.Mutation.make(
                testSuiteOutcome: .passed,
                point: .make(
                    mutationOperatorId: .ror,
                    filePath: "some/path",
                    position: .firstPosition
                ),
                snapshot: .null),
            userInfo: nil
        )
    }
}
