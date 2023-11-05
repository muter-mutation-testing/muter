import Difference
@testable import muterCore
import SnapshotTesting
import XCTest

public func XCTAssertEqual<T: Equatable>(
    _ expected: @autoclosure () throws -> T,
    _ received: @autoclosure () throws -> T,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    do {
        let expected = try expected()
        let received = try received()
        XCTAssertTrue(
            expected == received,
            "Found difference for \n" + diff(expected, received).joined(separator: ", "),
            file: file,
            line: line
        )
    } catch {
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

public func XCTAssertTypeEqual(
    _ lhs: Any?,
    _ rhs: (some Any).Type,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    guard let lhs else {
        return XCTFail("First argument should not be nil", file: file, line: line)
    }

    if type(of: lhs) != rhs {
        XCTFail("Expected \(rhs), got \(type(of: lhs))", file: file, line: line)
    }
}

public func AssertSnapshot(
    _ matching: String,
    file: StaticString = #filePath,
    line: UInt = #line,
    testName: String = #function
) {
    assertSnapshot(
        matching: matching,
        as: .lines,
        file: file,
        testName: testName,
        line: line
    )
}

public func AssertThrowsError(
    _ expression: @autoclosure () async throws -> some Any,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line,
    _ errorHandler: (_ error: Error) throws -> Void = { _ in }
) async {
    do {
        _ = try await expression()
        XCTFail(message(), file: file, line: line)
    } catch {
        do {
            try errorHandler(error)
        } catch {
            XCTFail("\(error)", file: file, line: line)
        }
    }
}

#if os(Linux)
public extension XCTestCase {
    func fulfillment(of expectations: [XCTestExpectation], timeout: TimeInterval, enforceOrder: Bool = false) async {
        return await withCheckedContinuation { continuation in
            // This function operates by blocking a background thread instead of one owned by libdispatch or by the
            // Swift runtime (as used by Swift concurrency.) To ensure we use a thread owned by neither subsystem, use
            // Foundation's Thread.detachNewThread(_:).
            Thread.detachNewThread { [self] in
                wait(for: expectations, timeout: timeout, enforceOrder: enforceOrder)
                continuation.resume()
            }
        }
    }
}
#endif