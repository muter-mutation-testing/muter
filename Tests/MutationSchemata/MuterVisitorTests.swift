@testable import muterCore
import SwiftParser
import TestingExtensions
import XCTest

final class MuterVisitorTests: MuterTestCase {
    private lazy var samplePath = "\(fixturesDirectory)/MutationExamples/sampleWithDisabledCode.swift"

    override func tearDownWithError() throws {
        try super.tearDownWithError()

        try FileManager.default.removeItem(atPath: samplePath)
    }

    func test_shouldIgnoreSkippedLines() throws {
        FileManager.default.createFile(
            atPath: samplePath,
            contents: sampleWithDisabledMutations.data(using: .utf8)
        )

        let sourceCode = try XCTUnwrap(PrepareSourceCode().prepareSourceCode(samplePath))
        let mappings = generateSchemataMappings(
            for: sourceCode.source,
            changes: sourceCode.changes
        )

        XCTAssertEqual(mappings.count, 1)

        XCTAssertEqual(mappings.first?.mutationSchemata.count, 1)
    }

    func test_shouldIgnoreComplexDisablingRules() throws {
        FileManager.default.createFile(
            atPath: samplePath,
            contents: sampleWithComplexDisableRules.data(using: .utf8)
        )

        let sourceCode = try XCTUnwrap(PrepareSourceCode().prepareSourceCode(samplePath))
        let mappings = generateSchemataMappings(
            for: sourceCode.source,
            changes: sourceCode.changes
        )

        XCTAssertEqual(mappings.count, 1)

        let ids = mappings.first?.mutationSchemata.map(\.mutationOperatorId)
        XCTAssertEqual(
            ids,
            [.ror, .removeSideEffects, .swapTernary]
        )
    }

    func test_shouldIgnoreTopLevelDisable() throws {
        FileManager.default.createFile(
            atPath: samplePath,
            contents: sampleWithTopLevelDisable.data(using: .utf8)
        )

        let sourceCode = try XCTUnwrap(PrepareSourceCode().prepareSourceCode(samplePath))
        let mappings = generateSchemataMappings(
            for: sourceCode.source,
            changes: sourceCode.changes
        )

        XCTAssertTrue(mappings.isEmpty)
    }
}

private let sampleWithComplexDisableRules =
    """
        import Foundation

        // muter:disable
        func f() {
            doSomething(testableSideEffect: true)
        }

        // muter:enable
        func f() {
            doSomething(testableSideEffect: false)
        }

        // muter:disable
        struct IgnoreMe {

            func f() -> Bool {
                // muter:enable
                let b = a == 5
                // muter:disable
                let e = a != 1
                // muter:enable
                return a ? "true" : "false"
            }
        }
    """

private let sampleWithDisabledMutations =
    """
    import Foundation

    func f() {
        doSomething(testableSideEffect: true)
    }

    // muter:disable
    func f() {
        doSomething(testableSideEffect: false)
    }

    struct IgnoreMe {

        func f() {
            doSomething(testableSideEffect: true)
            doSomething(testableSideEffect: true)
            doSomething(testableSideEffect: true)
            doSomething(testableSideEffect: false)
        }
    }
    """

private let sampleWithTopLevelDisable =
    """
    // muter:disable

    import Foundation

    func f() {
        doSomething(testableSideEffect: true)
    }

    func f() {
        doSomething(testableSideEffect: true)
        doSomething(testableSideEffect: false)
    }

    struct IgnoreMe {
        func f() {
            doSomething(testableSideEffect: true)
            doSomething(testableSideEffect: true)
            doSomething(testableSideEffect: true)
            doSomething(testableSideEffect: false)
        }
    }

    """
