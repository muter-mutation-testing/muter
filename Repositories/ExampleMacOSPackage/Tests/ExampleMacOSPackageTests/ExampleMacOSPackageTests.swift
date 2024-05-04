import XCTest
@testable import ExampleMacOSPackage

final class ExampleMacOSPackageTests: XCTestCase {
    func test() {
        XCTAssert(areEqual(5, and: 5))
        XCTAssertFalse(areEqual(5, and: 6))
    }
}
