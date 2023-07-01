@testable import muterCore
import XCTest

final class CreateTempDirectoryURLTests: MuterTestCase {
    private var state = RunCommandState()

    private let sut = CreateTempDirectoryURL()

    func test_whenItsAbleToCreateATempDirectory() {
        state.projectDirectoryURL = URL(string: "/tmp/some/projectName")!

        let result = sut.run(with: state)

        guard case let .success(stateChanges) = result else {
            XCTFail("expected success but got \(String(describing: result))")
            return
        }

        XCTAssertEqual(stateChanges, [.tempDirectoryUrlCreated(URL(fileURLWithPath: "/tmp/some/projectName_mutated"))])
    }
}
