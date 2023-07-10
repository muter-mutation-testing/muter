@testable import muterCore
import TestingExtensions
import Version
import XCTest

final class UpdateCheckTests: MuterTestCase {
    private let currentVersion = Version(1, 0, 0)
    private let state = RunCommandState()

    private lazy var sut = UpdateCheck(currentVersion: currentVersion)

    func test_notificationStarted() async throws {
        let expect = expectation(
            forNotification: .updateCheckStarted,
            object: nil,
            notificationCenter: notificationCenter
        )

        _ = try await sut.run(with: state)

        wait(for: [expect], timeout: 2)
    }

    func test_url() async throws {
        _ = try await sut.run(with: state)

        XCTAssertEqual(
            server.urlPassed?.absoluteString,
            "https://api.github.com/repos/muter-mutation-testing/muter/releases?per_page=1"
        )
    }

    func test_newVersionAvailable() async throws {
        server.dataToBeReturned = createReleaseJsonData("9.9.9")

        var newVersion: String?
        let expect = expectation(
            forNotification: .updateCheckFinished,
            object: nil,
            notificationCenter: notificationCenter
        ) { notification in
            newVersion = notification.object as? String
            return true
        }

        let result = try await sut.run(with: state)

        wait(for: [expect], timeout: 2)

        XCTAssertEqual(newVersion, "9.9.9")
        XCTAssertEqual(result, [.newVersionAvaiable("9.9.9")])
    }

    func test_noNewVersion() async throws {
        server.dataToBeReturned = createReleaseJsonData("0.0.0")

        var newVersion: String?
        let expect = expectation(
            forNotification: .updateCheckFinished,
            object: nil,
            notificationCenter: notificationCenter
        ) { notification in
            newVersion = notification.object as? String
            return true
        }

        let result = try await sut.run(with: state)

        wait(for: [expect], timeout: 2)

        XCTAssertTrue(result.isEmpty)
        XCTAssertNil(newVersion)
    }

    private func createReleaseJsonData(_ version: String = "") -> Data {
        """
         [
            {
                 "tag_name": "\(version)"
            }
         ]
        """.data(using: .utf8) ?? .init()
    }
}

private class VersionFetcherSpy: Spy {
    var methodCalls: [String] = []

    private(set) var urlPassed: URL?
    private(set) var optionsPassed: Data.ReadingOptions?
    var dataToBeReturned = Data()

    func fetch(_ url: URL, _ options: Data.ReadingOptions) throws -> Data {
        methodCalls.append(#function)

        urlPassed = url
        optionsPassed = options

        return dataToBeReturned
    }
}
