@testable import muterCore
import TestingExtensions
import XCTest

final class DiscoverProjectCoverageTests: MuterTestCase {
    private let state = RunCommandState()

    private lazy var sut = DiscoverProjectCoverage()

    func test_whenStepStarts_shouldFireNotification() async throws {
        state.muterConfiguration = MuterConfiguration(
            executable: "/path/to/xcodebuild",
            arguments: ["arg0", "arg1"]
        )

        let expectation = expectation(
            forNotification: .projectCoverageDiscoveryStarted,
            object: nil,
            notificationCenter: notificationCenter
        )

        _ = try await sut.run(with: state)

        await fulfillment(of: [expectation], timeout: 2)
    }

    func test_shouldReturnNullForUnknownBuildSytem() async throws {
        state.muterConfiguration = MuterConfiguration(
            executable: "/path/to/unknown",
            arguments: []
        )

        let result = try await sut.run(with: state)

        XCTAssertEqual(
            result,
            [.projectCoverage(.null)]
        )
    }

    func test_shouldChangeCurrentPath() async throws {
        state.muterConfiguration = MuterConfiguration(
            executable: "/path/to/xcodebuild",
            arguments: []
        )

        _ = try await sut.run(with: state)

        XCTAssertEqual(
            fileManager.methodCalls,
            [
                "changeCurrentDirectoryPath(_:)",
                "changeCurrentDirectoryPath(_:)"
            ]
        )
    }

    func test_whenStepFails_thenPostNotification() async throws {
        state.muterConfiguration = MuterConfiguration(
            executable: "/path/to/xcodebuild",
            arguments: []
        )

        process.enqueueStdOut("")

        let expectation = expectation(
            forNotification: .projectCoverageDiscoveryFinished,
            object: false,
            notificationCenter: notificationCenter
        )

        _ = try await sut.run(with: state)

        await fulfillment(of: [expectation], timeout: 2)
    }
}
