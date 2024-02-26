@testable import muterCore
import SnapshotTesting
import TestingExtensions
import XCTest

final class ROROperatorTests: MuterTestCase {
    private lazy var sourceWithConditionalLogic = sourceCode(
        fromFileAt: "\(mutationExamplesDirectory)/NegateConditionals/sampleWithConditionalOperators.swift"
    )!

    private lazy var sourceWithoutMutableCode = sourceCode(
        fromFileAt: "\(fixturesDirectory)/sourceWithoutMutableCode.swift"
    )!

    private lazy var conditionalConformanceConstraints = sourceCode(
        fromFileAt: "\(mutationExamplesDirectory)/NegateConditionals/conditionalConformanceConstraints.swift"
    )!

    func test_visitor() throws {
        let visitor = ROROperator.Visitor(
            sourceCodeInfo: sourceWithConditionalLogic
        )

        visitor.walk(sourceWithConditionalLogic.code)

        let actualSchematas = visitor.schemataMappings

        AssertSnapshot(actualSchematas.description)
    }

    func test_visitorOnFileWithoutOperator() {
        let visitor = ROROperator.Visitor(
            sourceCodeInfo: sourceWithoutMutableCode
        )

        visitor.walk(sourceWithoutMutableCode.code)

        XCTAssertTrue(visitor.schemataMappings.isEmpty)
    }

    func test_ignoresFunctionDeclarations() throws {
        let visitor = ROROperator.Visitor(
            sourceCodeInfo: sourceWithConditionalLogic
        )

        visitor.walk(sourceWithConditionalLogic.code)

        XCTAssertFalse(visitor.schemataMappings.codeBlocks.contains("func < "))
    }

    func test_ignoresConditionalConformancesConstraints() {
        let visitor = ROROperator.Visitor(
            sourceCodeInfo: conditionalConformanceConstraints
        )

        visitor.walk(conditionalConformanceConstraints.code)

        XCTAssertTrue(visitor.schemataMappings.isEmpty)
    }

    func test_rewriter() {
        let visitor = ROROperator.Visitor(
            sourceCodeInfo: sourceWithConditionalLogic
        )

        visitor.walk(sourceWithConditionalLogic.code)

        let actualSchematas = visitor.schemataMappings
        let rewriter = MuterRewriter(actualSchematas).rewrite(sourceWithConditionalLogic.code)

        AssertSnapshot(formatCode(rewriter.description))
    }
}
