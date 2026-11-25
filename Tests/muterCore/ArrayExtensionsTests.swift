@testable import muterCore
import XCTest

final class ArrayExtensionsTests: XCTestCase {

    // MARK: - chunked(into:) Tests

    func test_chunked_splitsArrayIntoEqualChunks() {
        let array = [1, 2, 3, 4, 5, 6]
        let chunks = array.chunked(into: 2)

        XCTAssertEqual(chunks.count, 3)
        XCTAssertEqual(chunks[0], [1, 2])
        XCTAssertEqual(chunks[1], [3, 4])
        XCTAssertEqual(chunks[2], [5, 6])
    }

    func test_chunked_handlesUnevenChunks() {
        let array = [1, 2, 3, 4, 5]
        let chunks = array.chunked(into: 2)

        XCTAssertEqual(chunks.count, 3)
        XCTAssertEqual(chunks[0], [1, 2])
        XCTAssertEqual(chunks[1], [3, 4])
        XCTAssertEqual(chunks[2], [5])
    }

    func test_chunked_handlesEmptyArray() {
        let array: [Int] = []
        let chunks = array.chunked(into: 3)

        XCTAssertEqual(chunks.count, 0)
    }

    func test_chunked_handlesSingleElement() {
        let array = [1]
        let chunks = array.chunked(into: 5)

        XCTAssertEqual(chunks.count, 1)
        XCTAssertEqual(chunks[0], [1])
    }

    func test_chunked_handlesChunkSizeLargerThanArray() {
        let array = [1, 2, 3]
        let chunks = array.chunked(into: 10)

        XCTAssertEqual(chunks.count, 1)
        XCTAssertEqual(chunks[0], [1, 2, 3])
    }

    func test_chunked_handlesChunkSizeOfOne() {
        let array = [1, 2, 3]
        let chunks = array.chunked(into: 1)

        XCTAssertEqual(chunks.count, 3)
        XCTAssertEqual(chunks[0], [1])
        XCTAssertEqual(chunks[1], [2])
        XCTAssertEqual(chunks[2], [3])
    }

    func test_chunked_handlesZeroChunkSize() {
        let array = [1, 2, 3]
        let chunks = array.chunked(into: 0)

        // Should return the whole array as a single chunk
        XCTAssertEqual(chunks.count, 1)
        XCTAssertEqual(chunks[0], [1, 2, 3])
    }

    func test_chunked_handlesNegativeChunkSize() {
        let array = [1, 2, 3]
        let chunks = array.chunked(into: -1)

        // Should return the whole array as a single chunk
        XCTAssertEqual(chunks.count, 1)
        XCTAssertEqual(chunks[0], [1, 2, 3])
    }

    func test_chunked_preservesOrder() {
        let array = ["a", "b", "c", "d", "e"]
        let chunks = array.chunked(into: 2)

        XCTAssertEqual(chunks.flatMap { $0 }, array)
    }

    func test_chunked_worksWithLargeArrays() {
        let array = Array(1...1000)
        let chunks = array.chunked(into: 50)

        XCTAssertEqual(chunks.count, 20)
        XCTAssertEqual(chunks.flatMap { $0 }.count, 1000)
    }
}
