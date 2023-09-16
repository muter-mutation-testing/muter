@testable import muterCore
import XCTest

final class CreateTempDirectoryURLTests: MuterTestCase {
    private var state = RunCommandState()

    private let sut = CreateTempDirectoryURL()

    func test_whenItsAbleToCreateATempDirectory() async throws {
        state.projectDirectoryURL = URL(string: "/tmp/some/projectName")!

        let result = try await sut.run(with: state)

        XCTAssertEqual(
            result,
            [.tempDirectoryUrlCreated(URL(fileURLWithPath: "/tmp/some/projectName_mutated"))]
        )
    }
}
