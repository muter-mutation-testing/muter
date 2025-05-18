@testable import muterCore
import SnapshotTesting
import SwiftSyntax
import TestingExtensions
import XCTest

final class RemoveSideEffectsOperatorTests: MuterTestCase {
    private lazy var sourceWithSideEffects = sourceCode(
        fromFileAt: "\(fixturesDirectory)/MutationExamples/SideEffect/sampleWithSideEffects.swift".platformNormalizedPath
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
}
