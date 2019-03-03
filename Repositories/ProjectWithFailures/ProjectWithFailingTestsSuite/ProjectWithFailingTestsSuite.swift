import XCTest

class ProjectWithFailingTestsSuite: XCTestCase {
    func testAlwaysFails() {
        XCTFail("it's important that this fails")
    }
}
