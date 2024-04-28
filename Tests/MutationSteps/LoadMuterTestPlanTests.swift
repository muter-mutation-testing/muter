import Foundation
@testable import muterCore
import TestingExtensions

final class LoadMuterTestPlanTests: MuterTestCase {
    private let state = MutationTestState()
    private let sut = LoadMuterTestPlan()

    func test_whenThereIsNotTestPlanUrl_thenThrowError() async throws {
        state.runOptions = .make(testPlanURL: nil)

        try await assertThrowsMuterError(
            await sut.run(with: state),
            .literal(reason: "Could not load the test plan")
        )
    }

    func test_whenCannotLoadTestPlan_thenThrowError() async throws {
        state.runOptions = .make(testPlanURL: URL(fileURLWithPath: "/path/to/test-plan"))

        try await assertThrowsMuterError(
            await sut.run(with: state),
            .literal(reason: "Could not load the test plan at path: /path/to/test-plan")
        )
    }

    func test_loadMuterTestPlan() async throws {
        state.runOptions = .make(testPlanURL: URL(fileURLWithPath: "/path/to/test-plan"))
        fileManager.fileContentsToReturn = MuterTestPlan.make(
            mutatedProjectPath: "/path/to/muted",
            projectCoverage: 23
        ).toData

        let result = try await sut.run(with: state)

        XCTAssertEqual(
            result, [
                .tempDirectoryUrlCreated(URL(fileURLWithPath: "/path/to/muted")),
                .projectCoverage(.init(percent: 23)),
                .mutationMappingsDiscovered([]),
            ]
        )
    }
}
