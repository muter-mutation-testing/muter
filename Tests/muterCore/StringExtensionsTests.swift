import XCTest
@testable import muterCore

final class StringExtensionsTests: XCTestCase {
    func testUTF8OffsetToCharOffset() {
        let string = "バルーンの表示判定"

        // Test valid offset
        XCTAssertEqual(string.convertToCharOffset(from: 3), 1)

        // Test invalid offset (negative)
        XCTAssertNil(string.convertToCharOffset(from: -1))

        // Test invalid offset (beyond string length)
        XCTAssertNil(string.convertToCharOffset(from: string.utf8.count + 1))
        
        XCTAssertNil(string.convertToCharOffset(from: 2))
    }
}
