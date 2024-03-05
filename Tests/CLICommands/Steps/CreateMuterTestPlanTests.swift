import Foundation
@testable import muterCore
import TestingExtensions
import XCTest

final class CreateMuterTestPlanTests: MuterTestCase {
    private let sut = CreateMuterTestPlan()

    func test_step() async throws {
        let state = makeState()

        let expect = expectation(
            forNotification: .testPlanFileCreated,
            object: nil,
            notificationCenter: notificationCenter
        ) { notification in
            let path = notification.object as? String
            XCTAssertEqual(path, "/path/to/project/muter-mappings.json")
            return true
        }

        _ = try await sut.run(with: state)

        await fulfillment(of: [expect], timeout: 2)

        XCTAssertTrue(writeFile.writeFileCalled)
        XCTAssertEqual(writeFile.pathPassed, "/path/to/project/muter-mappings.json")
    }

    private func makeState() -> MutationTestState {
        let state = MutationTestState()
        state.mutatedProjectDirectoryURL = URL(fileURLWithPath: "/path/to/project_mutated")
        state.projectDirectoryURL = URL(fileURLWithPath: "/path/to/project")
        state.projectCoverage = .make(percent: 47)
        state.mutationMapping = [
            SchemataMutationMapping(filePath: "/path/to/file")
        ]

        return state
    }
}
