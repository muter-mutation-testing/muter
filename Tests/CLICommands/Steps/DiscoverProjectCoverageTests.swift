import XCTest
import TestingExtensions

@testable import muterCore

final class DiscoverProjectCoverageTests: MuterTestCase {
    private let state = RunCommandState()
    
    private lazy var sut = DiscoverProjectCoverage()
    
    func test_whenStepStarts_shouldFireNotification() {
        state.muterConfiguration = MuterConfiguration(
            executable: "/path/to/xcodebuild",
            arguments: ["arg0", "arg1"]
        )
        
        let expectation = expectation(
            forNotification: .projectCoverageDiscoveryStarted,
            object: nil,
            notificationCenter: notificationCenter
        )
        
        _ = sut.run(with: state)
        
        wait(for: [expectation], timeout: 2)
    }
    
    func test_shouldReturnNullForUnknownBuildSytem() throws {
        state.muterConfiguration = MuterConfiguration(
            executable: "/path/to/unknown",
            arguments: []
        )
        
        let result = try XCTUnwrap(sut.run(with: state).get())
        
        XCTAssertEqual(
            result,
            [
                .projectCoverage(.null)
            ]
        )
    }
    
    func test_shouldChangeCurrentPath() {
        state.muterConfiguration = MuterConfiguration(
            executable: "/path/to/xcodebuild",
            arguments: []
        )
        
        _ = sut.run(with: state)
        
        XCTAssertEqual(
            fileManager.methodCalls,
            [
                "changeCurrentDirectoryPath(_:)",
                "changeCurrentDirectoryPath(_:)"
            ]
        )
    }
    
    func test_whenStepFails_thenPostNotification() {
        state.muterConfiguration = MuterConfiguration(
            executable: "/path/to/xcodebuild",
            arguments: []
        )

        process.stdoutToBeReturned = ""
        
        let expectation = expectation(
            forNotification: .projectCoverageDiscoveryFinished,
            object: false,
            notificationCenter: notificationCenter
        )
        
        _ = sut.run(with: state)
        
        wait(for: [expectation], timeout: 2)
    }
}
