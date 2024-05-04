import XCTest
@testable import ExampleiOSPackage

final class ExampleiOSPackageTests: XCTestCase {
    func test() {
        XCTAssert(areEqual(5, and: 5))
        XCTAssertFalse(areEqual(5, and: 6))
    }
}
