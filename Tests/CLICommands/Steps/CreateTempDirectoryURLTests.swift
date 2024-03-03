@testable import muterCore
import XCTest

final class CreateMutatedProjectDirectoryURLTests: MuterTestCase {
    private var state = RunCommandState()

    private let sut = CreateMutatedProjectDirectoryURL()

    func test_whenItsAbleToCreateATempDirectory() async throws {
        state.projectDirectoryURL = URL(string: "/tmp/some/projectName")!

        let result = try await sut.run(with: state)

        XCTAssertEqual(
            result,
            [.tempDirectoryUrlCreated(URL(fileURLWithPath: "/tmp/some/projectName_mutated"))]
        )
    }
}
