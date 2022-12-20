import XCTest
import Difference
import TestingExtensions

@testable import muterCore

public extension XCTestCase {
    var productsDirectory: URL {
        #if os(macOS)
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        fatalError("couldn't find the products directory")
        #else
        return Bundle.main.bundleURL
        #endif
    }

    var rootTestDirectory: String {
        return String(
            URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .withoutScheme()
        )
    }

    var fixturesDirectory: String { return "\(rootTestDirectory)/fixtures" }
    var configurationPath: String { return "\(fixturesDirectory)/\(MuterConfiguration.fileNameWithExtension)" }
    var mutationExamplesDirectory: String { return "\(fixturesDirectory)/MutationExamples" }

    var exampleMutationTestResults: [MutationTestOutcome.Mutation] {
        return [
            .make(
                testSuiteOutcome: .failed,
                point: MutationPoint(
                    mutationOperatorId: .ror,
                    filePath: "/tmp/file1.swift",
                    position: .firstPosition),
                snapshot: MutationOperatorSnapshot(
                    before: "==",
                    after: "!=",
                    description: "changed from == to !="
                )
            ),
            .make(
                testSuiteOutcome: .failed,
                point: MutationPoint(
                    mutationOperatorId: .ror,
                    filePath: "/tmp/file1.swift",
                    position: .firstPosition),
                snapshot: MutationOperatorSnapshot(
                    before: "==",
                    after: "!=",
                    description: "changed from == to !="
                )
            ),
            .make(
                testSuiteOutcome: .passed,
                point: MutationPoint(
                    mutationOperatorId: .ror,
                    filePath: "/tmp/file1.swift",
                    position: .firstPosition),
                snapshot: MutationOperatorSnapshot(
                    before: "==",
                    after: "!=",
                    description: "changed from == to !="
                )
            ),
            .make(
                testSuiteOutcome: .failed,
                point: MutationPoint(
                    mutationOperatorId: .removeSideEffects,
                    filePath: "/tmp/file2.swift",
                    position: .firstPosition),
                snapshot: MutationOperatorSnapshot(
                    before: "==",
                    after: "!=",
                    description: "changed from == to !="
                )
            ),
            .make(
                testSuiteOutcome: .failed,
                point: MutationPoint(
                    mutationOperatorId: .removeSideEffects,
                    filePath: "/tmp/file2.swift",
                    position: .firstPosition),
                snapshot: MutationOperatorSnapshot(
                    before: "==",
                    after: "!=",
                    description: "changed from == to !="
                )
            ),
            .make(
                testSuiteOutcome: .failed,
                point: MutationPoint(
                    mutationOperatorId: .ror,
                    filePath: "/tmp/file3.swift",
                    position: .firstPosition),
                snapshot: MutationOperatorSnapshot(
                    before: "==",
                    after: "!=",
                    description: "changed from == to !="
                )
            ),
            .make(
                testSuiteOutcome: .passed,
                point: MutationPoint(
                    mutationOperatorId: .ror,
                    filePath: "/tmp/file3.swift",
                    position: .firstPosition),
                snapshot: MutationOperatorSnapshot(
                    before: "==",
                    after: "!=",
                    description: "changed from == to !="
                )
            ),
            .make(
                testSuiteOutcome: .passed,
                point: MutationPoint(
                    mutationOperatorId: .ror,
                    filePath: "/tmp/file3.swift",
                    position: .firstPosition),
                snapshot: MutationOperatorSnapshot(
                    before: "==",
                    after: "!=",
                    description: "changed from == to !="
                )
            ),
            .make(
                testSuiteOutcome: .passed,
                point: MutationPoint(
                    mutationOperatorId: .ror,
                    filePath: "/tmp/file 4.swift", // this file name intentionally has a space in it
                    position: .firstPosition),
                snapshot: MutationOperatorSnapshot(
                    before: "==",
                    after: "!=",
                    description: "changed from == to !="
                )
            ),
        ]
    }
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
