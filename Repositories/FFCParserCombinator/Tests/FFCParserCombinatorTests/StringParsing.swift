//
//  StringParsingTests.swift
//  FFCParserCombinatorTests
//
//  Created by Fabian Canas on 6/9/18.
//

import XCTest
import FFCParserCombinator

class StringParsingTests: XCTestCase {

    let float = { Double($0)! } <^> BasicParser.floatingPointString

    let signedFloat = ({ Double($0)! } <^> BasicParser.negation.optional.followed(by: BasicParser.floatingPointString) { (neg, num) -> String in
        (neg ?? "") + num
        })

    func testFloatingPoint() {
        XCTAssertNil(float.run("")?.0)
        XCTAssertNil(float.run("A0.1")?.0)
        XCTAssertNil(float.run("\n0.1")?.0)
        XCTAssertNil(float.run("1")?.0)
        XCTAssertNil(float.run("0")?.0)
        XCTAssertNil(float.run("-1")?.0)
        XCTAssertNil(float.run("-1.1")?.0)

        XCTAssertEqual(float.run("0.1")!.0, 0.1, accuracy: 0.0001)
        XCTAssertEqual(float.run("1.1")!.0, 1.1, accuracy: 0.0001)
        XCTAssertEqual(float.run("18446744073709551615.18446744073709551615")!.0, 18446744073709551615.18446744073709551615, accuracy: 0.0001)
    }

    func testSignedFloatingPoint() {
        XCTAssertNil(signedFloat.run("")?.0)
        XCTAssertNil(signedFloat.run("A0.1")?.0)
        XCTAssertNil(signedFloat.run("\n0.1")?.0)
        XCTAssertNil(signedFloat.run("1")?.0)
        XCTAssertNil(signedFloat.run("0")?.0)
        XCTAssertNil(signedFloat.run("-1")?.0)

        XCTAssertEqual(signedFloat.run("0.1")!.0, 0.1, accuracy: 0.0001)
        XCTAssertEqual(signedFloat.run("1.1")!.0, 1.1, accuracy: 0.0001)
        XCTAssertEqual(signedFloat.run("18446744073709551615.18446744073709551615")!.0, 18446744073709551615.18446744073709551615, accuracy: 0.0001)

        XCTAssertEqual(signedFloat.run("-0.1")!.0, -0.1, accuracy: 0.0001)
        XCTAssertEqual(signedFloat.run("-1.1")!.0, -1.1, accuracy: 0.0001)
        XCTAssertEqual(signedFloat.run("-18446744073709551615.18446744073709551615")!.0, -18446744073709551615.18446744073709551615, accuracy: 0.0001)
    }

    func testUInt() {
        // Not a number
        XCTAssertNil(UInt.parser.run("")?.0)
        XCTAssertNil(UInt.parser.run("a")?.0)
        XCTAssertNil(UInt.parser.run("abcdef")?.0)
        XCTAssertNil(UInt.parser.run("-1")?.0)

        // Normal numbers in full range
        XCTAssertEqual(UInt.parser.run(String(UInt.min))?.0, UInt.min)
        XCTAssertEqual(UInt.parser.run("0")?.0, 0)
        XCTAssertEqual(UInt.parser.run("1")?.0, 1)
        XCTAssertEqual(UInt.parser.run("1234")?.0, 1234)
        // 2^64-1 (18446744073709551615)
        // Defined as the maximum for "decimal-integer" in HLS specification
        XCTAssertEqual(UInt.parser.run("18446744073709551615")?.0, 18446744073709551615)
        XCTAssertEqual(UInt.parser.run(String(UInt.max))?.0, UInt.max)

        // Starts with numbers
        XCTAssertEqual(UInt.parser.run("0abcdef")?.0, 0)
        XCTAssertEqual(UInt.parser.run("1-")?.0, 1)
        XCTAssertEqual(UInt.parser.run("1234&234")?.0, 1234)
        XCTAssertEqual(UInt.parser.run("18446744073709551615\n")?.0, 18446744073709551615)

        // Not a number
        XCTAssertNil(UInt.parser.run("")?.0)
        XCTAssertNil(UInt.parser.run("A")?.0)
        XCTAssertNil(UInt.parser.run("ABCDEF")?.0)
        XCTAssertNil(UInt.parser.run("-1")?.0)
    }

    func testInt() {
        // Negative
        XCTAssertEqual(Int.parser.run(String(Int.min))?.0, Int.min)
        XCTAssertEqual(Int.parser.run("-9223372036854775807")?.0, -9223372036854775807)
        XCTAssertEqual(Int.parser.run("0")?.0, 0)
        XCTAssertEqual(Int.parser.run("-0")?.0, 0)
        XCTAssertEqual(Int.parser.run("1")?.0, 1)
        XCTAssertEqual(Int.parser.run("-1")?.0, -1)
        XCTAssertEqual(Int.parser.run("1234")?.0, 1234)
        XCTAssertEqual(Int.parser.run("-1234")?.0, -1234)
        // 2^64-1 >> 1 (9223372036854775807)
        // Defined as the maximum for "decimal-integer" in HLS specification
        XCTAssertEqual(Int.parser.run("9223372036854775807")?.0, 9223372036854775807)
        XCTAssertEqual(Int.parser.run(String(Int.max))?.0, Int.max)
    }

    func testDouble() {
        let d = Double.parser

        XCTAssertEqual(Double.parser.run(String(Double.leastNormalMagnitude))!.0, Double.leastNormalMagnitude, accuracy: 1e-322)

        XCTAssertEqual(d.run("0")?.0, 0)
        XCTAssertEqual(d.run("1")?.0, 1)
        XCTAssertEqual(d.run("12")?.0, 12)
        XCTAssertEqual(d.run("12.5")?.0, 12.5)
        XCTAssertEqual(d.run("-12.5")?.0, -12.5)

        XCTAssertEqual(d.run("0e+0")?.0, 0)
        XCTAssertEqual(d.run("0e+100")?.0, 0)
        XCTAssertEqual(d.run("0e-100")?.0, 0)

        XCTAssertEqual(d.run("1e+0")?.0, 1)
        XCTAssertEqual(d.run("1e+1")?.0, 10)
        XCTAssertEqual(d.run("12e-1")?.0, 1.2)
        XCTAssertEqual(d.run("12.5e+1")?.0, 125)
        XCTAssertEqual(d.run("-12.5e-1")?.0, -1.25)
        XCTAssertEqual(d.run("-12.5e+1")?.0, -125)

        XCTAssertEqual(Double("1.7976931348623e308")!, Double.greatestFiniteMagnitude, accuracy: 1e+295)
        // Currect reconstruction method loses too much precision to test this way
        // XCTAssertEqual(Double.parser.run(String(Double.greatestFiniteMagnitude))!.0, Double.greatestFiniteMagnitude)

        XCTAssertEqual(Double.parser.run(String(Double.leastNonzeroMagnitude))!.0, Double.leastNonzeroMagnitude)
    }

    func testNewlines() {
        let s = "Line\nLine\n\rLine\n\rLine\nLine"
        let line = "Line" <* BasicParser.newline
        let result = line.many.run(s)!
        XCTAssertEqual(result.0, ["Line", "Line", "Line", "Line"])
        XCTAssertEqual(result.1, "Line")
    }

    func testComposition() {
        let doubleRepeater = (repeatElement <^> Double.parser) <*> (BasicParser.x *> Int.parser)

        let result = doubleRepeater.run("1.23x4")!

        XCTAssertEqual(Array(result.0), Array(repeatElement(1.23, count: 4)))
    }

    static var allTests = [
        ("testFloatingPoint", testFloatingPoint),
        ("testSignedFloatingPoint", testSignedFloatingPoint),
        ("testInt", testInt),
        ("testUInt", testUInt),
        ("testDouble", testDouble),
        ("testNewlines", testNewlines),
        ("testComposition", testComposition)
        ]

}
