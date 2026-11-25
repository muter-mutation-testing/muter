@testable import muterCore
import XCTest

final class RegionTests: XCTestCase {
    // `two ? kOn : kOff` on line 220, after an uncovered `one ? kOn : kOff` on line 217.
    private let uncoveredLine217 = Region(lineStart: 217, columnStart: 40, lineEnd: 217, columnEnd: 96)
    private let ternaryOnLine220 = Region(lineStart: 220, columnStart: 40, lineEnd: 220, columnEnd: 96)

    func test_aRegionDoesNotContainCodeOnALaterLine() {
        XCTAssertFalse(uncoveredLine217.contains(ternaryOnLine220))
    }

    func test_aRegionDoesNotContainCodeOnAnEarlierLine() {
        XCTAssertFalse(ternaryOnLine220.contains(uncoveredLine217))
    }

    func test_aRegionContainsCodeInsideIt() {
        let ifBody = Region(lineStart: 216, columnStart: 30, lineEnd: 218, columnEnd: 14)

        XCTAssertTrue(ifBody.contains(uncoveredLine217))
        XCTAssertTrue(uncoveredLine217.contains(uncoveredLine217))
    }

    func test_aRegionDoesNotContainCodeThatOnlyOverlapsIt() {
        let elseBranch = Region(lineStart: 220, columnStart: 69, lineEnd: 220, columnEnd: 96)

        XCTAssertFalse(elseBranch.contains(ternaryOnLine220))
    }

    func test_onTheSameLine_columnsDecide() {
        let region = Region(lineStart: 10, columnStart: 5, lineEnd: 10, columnEnd: 20)

        XCTAssertTrue(region.contains(Region(lineStart: 10, columnStart: 5, lineEnd: 10, columnEnd: 20)))
        XCTAssertFalse(region.contains(Region(lineStart: 10, columnStart: 4, lineEnd: 10, columnEnd: 20)))
        XCTAssertFalse(region.contains(Region(lineStart: 10, columnStart: 5, lineEnd: 10, columnEnd: 21)))
    }
}
