@testable import muterCore
import SwiftParser
import XCTest

final class DisableDirectivesTests: MuterTestCase {
    // MARK: Reading a comment

    func test_readsADirectiveForAllOperators() {
        XCTAssertEqual(
            DisableDirectives.directive(from: "// muter:disable", line: 3),
            .init(isDisable: true, scope: .block, line: 3, operators: [])
        )
        XCTAssertEqual(
            DisableDirectives.directive(from: "// muter:enable", line: 4),
            .init(isDisable: false, scope: .block, line: 4, operators: [])
        )
    }

    func test_readsTheOperatorList() {
        XCTAssertEqual(
            DisableDirectives.directive(
                from: "// muter:disable RelationalOperatorReplacement, SwapTernary RemoveSideEffects",
                line: 1
            )?.operators,
            [.ror, .swapTernary, .removeSideEffects]
        )
    }

    func test_readsTheNextLineOption() {
        XCTAssertEqual(
            DisableDirectives.directive(from: "// muter:disable next-line SwapTernary", line: 1),
            .init(isDisable: true, scope: .nextLine, line: 1, operators: [.swapTernary])
        )
    }

    func test_ignoresTheReasonAfterAColon() {
        XCTAssertEqual(
            DisableDirectives.directive(
                from: "// muter:disable next-line: SwapTernary is only a log message",
                line: 1
            ),
            .init(isDisable: true, scope: .nextLine, line: 1, operators: [])
        )
    }

    func test_commentWithoutAKnownOperatorAppliesToAllOperators() {
        XCTAssertEqual(
            DisableDirectives.directive(from: "// muter:disable legacy code", line: 1)?.operators,
            []
        )
    }

    func test_ignoresOtherComments() {
        XCTAssertNil(DisableDirectives.directive(from: "// a normal comment", line: 1))
    }

    // MARK: Turning operators off

    func test_blockTurnsOffFromItsLineUntilEnable() {
        let directives = DisableDirectives(directives: [
            .init(isDisable: true, scope: .block, line: 2, operators: []),
            .init(isDisable: false, scope: .block, line: 5, operators: []),
        ])

        XCTAssertEqual(
            (1 ... 6).map { directives.isDisabled(.ror, onLine: $0) },
            [false, true, true, true, false, false]
        )
    }

    func test_blockTurnsOffOnlyTheListedOperators() {
        let directives = DisableDirectives(directives: [
            .init(isDisable: true, scope: .block, line: 1, operators: [.ror]),
        ])

        XCTAssertTrue(directives.isDisabled(.ror, onLine: 2))
        XCTAssertFalse(directives.isDisabled(.swapTernary, onLine: 2))
    }

    func test_enableTurnsOnOnlyTheListedOperators() {
        let directives = DisableDirectives(directives: [
            .init(isDisable: true, scope: .block, line: 1, operators: []),
            .init(isDisable: false, scope: .block, line: 3, operators: [.ror]),
        ])

        XCTAssertFalse(directives.isDisabled(.ror, onLine: 4))
        XCTAssertTrue(directives.isDisabled(.swapTernary, onLine: 4))
    }

    func test_nextLineTurnsOffOnlyTheNextLine() {
        let directives = DisableDirectives(directives: [
            .init(isDisable: true, scope: .nextLine, line: 2, operators: []),
        ])

        XCTAssertEqual(
            (1 ... 4).map { directives.isDisabled(.ror, onLine: $0) },
            [false, false, true, false]
        )
    }

    func test_nextLineEnableWinsOverABlock() {
        let directives = DisableDirectives(directives: [
            .init(isDisable: true, scope: .block, line: 1, operators: []),
            .init(isDisable: false, scope: .nextLine, line: 3, operators: []),
        ])

        XCTAssertEqual(
            (2 ... 5).map { directives.isDisabled(.ror, onLine: $0) },
            [true, true, false, true]
        )
    }

    func test_readsLeadingAndTrailingCommentsWithTheirLines() {
        let source = Parser.parse(source: """
        // muter:disable
        let a = 1 // muter:enable SwapTernary
        func f() {
            // muter:disable next-line RemoveSideEffects
            g()
        }
        """)

        XCTAssertEqual(
            DisableDirectives(source: source, fileName: "file.swift").directives,
            [
                .init(isDisable: true, scope: .block, line: 1, operators: []),
                .init(isDisable: false, scope: .block, line: 2, operators: [.swapTernary]),
                .init(isDisable: true, scope: .nextLine, line: 4, operators: [.removeSideEffects]),
            ]
        )
    }

    // MARK: Discovery

    func test_discoveryIgnoresTheMutantsThatTheCommentsTurnOff() throws {
        let source = try sourceCode("""
        import Foundation

        func f(_ a: Int, _ b: Bool) -> String {
            // muter:disable next-line RelationalOperatorReplacement
            let c = a == 1 && b
            // muter:disable next-line: the ternary spans two lines
            let d = c
                ? "yes" : "no"
            // muter:disable next-line
            doSomething(testableSideEffect: true)
            // muter:disable RemoveSideEffects
            doSomething()
            // muter:enable
            doSomething(testableSideEffect: a > 2)
            return d
        }
        """)

        let mappings = generateSchemataMappings(
            for: .init(path: "/path/to/file", code: source),
            changes: .null
        )

        let mutants = mappings.flatMap(\.mutationSchemata).map {
            "\($0.mutationOperatorId.rawValue)@\($0.position.line)"
        }
        XCTAssertEqual(
            mutants.sorted(),
            [
                "ChangeLogicalConnector@5",
                "RelationalOperatorReplacement@14",
                "RemoveSideEffects@14",
            ]
        )
    }
}
