import XCTest

class ModuleTests: XCTestCase {
    func test() {
        XCTAssert(areEqual(5, and: 5))
        XCTAssertFalse(areEqual(5, and: 6))
    }
}
