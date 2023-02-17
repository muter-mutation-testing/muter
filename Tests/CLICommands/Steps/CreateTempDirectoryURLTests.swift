import XCTest

@testable import muterCore

final class CreateTempDirectoryURLTests: XCTestCase {
    private var state = RunCommandState()

    private let sut = CreateTempDirectoryURL()

    func test_whenItsAbleToCreateATempDirectory() {
        state.projectDirectoryURL = URL(string: "/tmp/some/projectName")!
        
        let result = sut.run(with: state)
        
        guard case .success(let stateChanges) = result else {
            XCTFail("expected success but got \(String(describing: result))")
            return
        }
        
        XCTAssertEqual(stateChanges, [.tempDirectoryUrlCreated(URL(fileURLWithPath: "/tmp/some/projectName_mutated"))])
    }
}
