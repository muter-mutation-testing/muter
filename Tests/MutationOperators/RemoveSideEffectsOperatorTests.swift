@testable import muterCore
import SnapshotTesting
import SwiftSyntax
import TestingExtensions
import XCTest

final class RemoveSideEffectsOperatorTests: MuterTestCase {
    private lazy var sourceWithSideEffects = sourceCode(
        fromFileAt: "\(fixturesDirectory)/MutationExamples/SideEffect/sampleWithSideEffects.swift"
    )!

    func test_visitor() throws {
        let visitor = RemoveSideEffectsOperator.Visitor(
            sourceCodeInfo: sourceWithSideEffects
        )

        visitor.walk(sourceWithSideEffects.code)

        let actualSchemata = visitor.schemataMappings

        assertMutationPositions(
            actualSchemata, [
                MutationPosition(utf8Offset: 186, line: 10, column: 27),
                MutationPosition(utf8Offset: 423, line: 20, column: 62),
                MutationPosition(utf8Offset: 643, line: 30, column: 71),
                MutationPosition(utf8Offset: 713, line: 31, column: 70),
                MutationPosition(utf8Offset: 906, line: 39, column: 6),
                MutationPosition(utf8Offset: 80, line: 3, column: 27),
                MutationPosition(utf8Offset: 994, line: 44, column: 19),
                MutationPosition(utf8Offset: 1049, line: 48, column: 19),
                MutationPosition(utf8Offset: 1099, line: 52, column: 19),
                MutationPosition(utf8Offset: 1138, line: 56, column: 19),
            ]
        )
    }

    private func assertMutationPositions(
        _ actual: SchemataMutationMapping,
        _ expected: [MutationPosition],
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let actualSorted = actual.mutationSchemata.map(\.position).sorted()
        let expectedSoted = expected.sorted()

        XCTAssertEqual(actualSorted, expectedSoted, file: file, line: line)
    }

    func test_rewriter() throws {
        let visitor = RemoveSideEffectsOperator.Visitor(
            sourceCodeInfo: sourceWithSideEffects
        )

        visitor.walk(sourceWithSideEffects.code)

        let rewriter = MuterRewriter(visitor.schemataMappings).rewrite(sourceWithSideEffects.code)

        AssertSnapshot(formatCode(rewriter.description))
    }

    func test_sideEffectsInDoStatement() throws {
        let source = try sourceCode(
            """
            static func validate(_ type: ParsableArguments.Type, parent: InputKey?) -> ParsableArgumentsValidatorError? {
              let argumentKeys: [InputKey] = Mirror(reflecting: type.init())
                .children
                .compactMap { child in
                  guard
                    let codingKey = child.label,
                    let _ = child.value as? ArgumentSetProvider
                    else { return nil }

                  // Property wrappers have underscore-prefixed names
                  return InputKey(name: codingKey, parent: parent)
              }
              guard argumentKeys.count > 0 else {
                return nil
              }
              do {
                let _ = try type.init(from: Validator(argumentKeys: argumentKeys))
                return InvalidDecoderError(type: type)
              } catch let result as Validator.ValidationResult {
                switch result {
                case .missingCodingKeys(let keys):
                  return MissingKeysError(missingCodingKeys: keys)
                case .success:
                  return nil
                }
              } catch {
                fatalError("Unexpected validation error: error")
              }
            }
            """
        )
        let visitor = RemoveSideEffectsOperator.Visitor(
            sourceCodeInfo: .init(path: "/path/to/file", code: source)
        )

        visitor.walk(source)

        let rewriter = MuterRewriter(visitor.schemataMappings).rewrite(source)

        AssertSnapshot(formatCode(rewriter.description))
    }

    // MARK: - Nested code block regression (muter#283)

    /// Proves that the schemata rewriter emits mutation switches at BOTH nesting
    /// levels when nested for loops each contain RemoveSideEffects targets.
    ///
    /// The bug: `SchemataMutationMapping` keys `CodeBlockItemListSyntax` nodes
    /// by `SyntaxIdentifier` (pointer + tree index). When `MuterRewriter`
    /// replaces an outer code block with a mutation switch, all inner nodes get
    /// new identities. The dictionary lookup for the inner code block then fails,
    /// silently dropping the inner mutation. At runtime the inner mutation's env
    /// var has no corresponding if-branch, so the original code always runs, tests
    /// pass, and muter reports a false "survived".
    func test_nestedForLoopsProduceMutationSwitchesAtBothLevels() throws {
        let source = try sourceCode(
            """
            func process(groups: [[String]]) {
                for group in groups {
                    sideEffect("outer")
                    for item in group {
                        sideEffect("inner")
                    }
                }
            }
            """
        )

        let sourceInfo = SourceCodeInfo(path: "/path/to/file", code: source)
        let visitor = RemoveSideEffectsOperator.Visitor(
            sourceCodeInfo: sourceInfo
        )

        visitor.walk(source)

        let mappings = visitor.schemataMappings

        // The visitor must find two mutations:
        // 1. Removing sideEffect("outer") from the outer for body
        // 2. Removing sideEffect("inner") from the inner for body
        XCTAssertEqual(
            mappings.mutationSchemata.count, 2,
            "Visitor should register mutations at both nesting levels"
        )

        // Now rewrite and verify both mutation switches appear
        let rewritten = MuterRewriter(mappings).rewrite(source).description

        let mutationSwitchCount = rewritten
            .components(separatedBy: "ProcessInfo.processInfo.environment[")
            .count - 1

        // There are 2 schemata so there must be 2 env-var checks in the
        // rewritten source — one for the outer mutation, one for the inner.
        XCTAssertEqual(
            mutationSwitchCount, 2,
            "Rewritten source must contain mutation switches at both nesting "
            + "levels. Found \(mutationSwitchCount) instead of 2. "
            + "This indicates the inner mutation switch was silently dropped "
            + "because the CodeBlockItemListSyntax identity changed when the "
            + "outer code block was rewritten."
        )

        // Additionally verify each specific schemata ID appears
        for schema in mappings.mutationSchemata {
            XCTAssertTrue(
                rewritten.contains(schema.id),
                "Rewritten source must contain a mutation switch for schemata "
                + "'\(schema.id)' but it was not found. The inner mutation was "
                + "silently dropped during rewriting."
            )
        }
    }
}
