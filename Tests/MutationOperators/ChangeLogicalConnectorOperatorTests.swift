import XCTest
import SwiftSyntax
import SwiftSyntaxParser

@testable import muterCore

final class ChangeLogicalConnectorOperatorTests: XCTestCase {
    private lazy var sourceWithLogicalOperators = sourceCode(
        fromFileAt: "\(fixturesDirectory)/MutationExamples/LogicalOperator/sampleWithLogicalOperators.swift"
    )!
    
    private lazy var sampleWithCompilerDirectives = sourceCode(
        fromFileAt: "\(fixturesDirectory)/MutationExamples/LogicalOperator/sampleWithCompilerDirectives.swift"
    )!
    
    func test_rewriter_andToOr() throws {
        let line2Column18 = MutationPosition(utf8Offset: 101, line: 6, column: 18)
        let expectedSource = sourceCode(fromFileAt: "\(self.fixturesDirectory)/MutationExamples/LogicalOperator/changedANDOperator.swift")!

        let rewriter = ChangeLogicalConnectorOperator.Rewriter(positionToMutate: line2Column18)
        let mutatedSource = rewriter.visit(sourceWithLogicalOperators.code)

        XCTAssertEqual(mutatedSource.description, expectedSource.code.description)
    }
    
    func test_rewriter_orToAnd() {
        let line6Column17 = MutationPosition(utf8Offset: 160, line: 10, column: 17)
        let expectedSource = sourceCode(fromFileAt: "\(self.fixturesDirectory)/MutationExamples/LogicalOperator/changedOROperator.swift")!

        let rewriter = ChangeLogicalConnectorOperator.Rewriter(positionToMutate: line6Column17)
        let mutatedSource = rewriter.visit(sourceWithLogicalOperators.code)

        XCTAssertEqual(mutatedSource.description, expectedSource.code.description)
    }
    
    func test_visitor() {
        let visitor = ChangeLogicalConnectorOperator.Visitor(sourceFileInfo: sourceWithLogicalOperators.asSourceFileInfo)
        visitor.walk(sourceWithLogicalOperators.code)

        guard visitor.positionsOfToken.count == 2 else {
            return XCTFail("Expected 2 tokens to be discovered, got \(visitor.positionsOfToken.count) instead")
        }

        XCTAssertEqual(visitor.positionsOfToken[safe: 0]?.line, 6)
        XCTAssertEqual(visitor.positionsOfToken[safe: 1]?.line, 10)
    }
    
    func test_ignoresCompilerDirectives() {
        let visitor = ChangeLogicalConnectorOperator.Visitor(sourceFileInfo: sampleWithCompilerDirectives.asSourceFileInfo)
        visitor.walk(sampleWithCompilerDirectives.code)

        guard visitor.positionsOfToken.count == 1 else {
            return XCTFail("Expected 2 tokens to be discovered, got \(visitor.positionsOfToken.count) instead")
        }

        XCTAssertEqual(visitor.positionsOfToken[safe: 0]?.line, 7)
    }
}

final class ChangeLogicalConnectorOperator_SchmataTests: XCTestCase {
    private lazy var sourceWithLogicalOperators = sourceCode(
        fromFileAt: "\(fixturesDirectory)/MutationExamples/LogicalOperator/sampleWithLogicalOperators.swift"
    )!
    
    private lazy var sampleWithCompilerDirectives = sourceCode(
        fromFileAt: "\(fixturesDirectory)/MutationExamples/LogicalOperator/sampleWithCompilerDirectives.swift"
    )!
    
    func test_rewriter_andToOr() throws {
        let line2Column18 = MutationPosition(utf8Offset: 101, line: 6, column: 18)
        let expectedSource = sourceCode(fromFileAt: "\(self.fixturesDirectory)/MutationExamples/LogicalOperator/changedANDOperator.swift")!

        let rewriter = ChangeLogicalConnectorOperator.Rewriter(positionToMutate: line2Column18)
        let mutatedSource = rewriter.visit(sourceWithLogicalOperators.code)

        XCTAssertEqual(mutatedSource.description, expectedSource.code.description)
    }
    
    func test_rewriter_orToAnd() {
        let line6Column17 = MutationPosition(utf8Offset: 160, line: 10, column: 17)
        let expectedSource = sourceCode(fromFileAt: "\(self.fixturesDirectory)/MutationExamples/LogicalOperator/changedOROperator.swift")!

        let rewriter = ChangeLogicalConnectorOperator.Rewriter(positionToMutate: line6Column17)
        let mutatedSource = rewriter.visit(sourceWithLogicalOperators.code)

        XCTAssertEqual(mutatedSource.description, expectedSource.code.description)
    }
    
    func test_visitor() throws {
        let visitor = ChangeLogicalConnectorOperator.SchemataVisitor(
            sourceFileInfo: sourceWithLogicalOperators.asSourceFileInfo
        )
        
        visitor.walk(sourceWithLogicalOperators.code)

        let schemataMappings = visitor.schemataMappings
        
        XCTAssertEqual(schemataMappings.count, 2)
        
        let sortedKeys = schemataMappings.keys
            .map(\.description)
            .sorted()

        XCTAssertEqual(
            sortedKeys,
            [
                "\n    return false && false",
                "\n    return true || true"
            ]
        )
        
        let sortedValues = Array(schemataMappings.values.reduce([], +)).sorted()

        XCTAssertEqual(sortedValues.count, 2)
        XCTAssertEqual(
            sortedValues[0],
            try .make(
                id: "LogicalOperator_@10_160_17",
                syntaxMutation: "\n    return true && true",
                positionInSourceCode: MutationPosition(
                    utf8Offset: 160,
                    line: 10,
                    column: 17
                ),
                snapshot: .make(
                    before: "||",
                    after: "&&",
                    description: "changed || to &&"
                )
            )
        )
        
        XCTAssertEqual(
            sortedValues[1],
            try .make(
                id: "LogicalOperator_@6_101_18",
                syntaxMutation: "\n    return false || false",
                positionInSourceCode: MutationPosition(
                    utf8Offset: 101,
                    line: 6,
                    column: 18
                ),
                snapshot: .make(
                    before: "&&",
                    after: "||",
                    description: "changed && to ||"
                )
            )
        )
    }
    
    func test_ignoresCompilerDirectives() {
        let visitor = ChangeLogicalConnectorOperator.SchemataVisitor(
            sourceFileInfo: sampleWithCompilerDirectives.asSourceFileInfo
        )

        visitor.walk(sampleWithCompilerDirectives.code)
        
        XCTAssertTrue(visitor.schemataMappings.isEmpty)
    }
}

// MOVE

extension Schemata {
    static func make(
        id: String = "",
        syntaxMutation: String = "",
        positionInSourceCode: MutationPosition = .null,
        snapshot: MutationOperatorSnapshot = .null
    ) throws -> Schemata {
        Schemata(
            id: id,
            syntaxMutation: try SyntaxParser.parse(source: syntaxMutation).statements,
            positionInSourceCode: positionInSourceCode,
            snapshot: snapshot
        )
    }
}
