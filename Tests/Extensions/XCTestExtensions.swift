import XCTest
import Difference

@testable import muterCore

public func XCTAssertEqual<T: Equatable>(
    _ expected: @autoclosure () throws -> T,
    _ received: @autoclosure () throws -> T,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    do {
        let expected = try expected()
        let received = try received()
        XCTAssertTrue(expected == received, "Found difference for \n" + diff(expected, received).joined(separator: ", "), file: file, line: line)
    }
    catch {
        XCTFail("Caught error while testing: \(error)", file: file, line: line)
    }
}

public func XCTAssertTrue(
    _ expression: @autoclosure () throws -> Bool?,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) {
    guard let actual = try? expression() else {
        return XCTFail("Expected boolean, got nil")
    }

    XCTAssertTrue(actual, message(), file: file, line: line)
}

public func XCTAssertFalse(
    _ expression: @autoclosure () throws -> Bool?,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) {
    guard let actual = try? expression() else {
        return XCTFail("Expected boolean, got nil")
    }

    XCTAssertFalse(actual, message(), file: file, line: line)
}

public func XCTAssertTypeEqual<A>(
    _ lhs: Any?,
    _ rhs: A.Type,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    guard let lhs = lhs else {
        return XCTFail("First argument should not be nil", file: file, line: line)
    }

    if type(of: lhs) != rhs {
        XCTFail("Expected \(rhs), got \(type(of: lhs))", file: file, line: line)
    }
}
