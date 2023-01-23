import XCTest
import SwiftSyntax
import SwiftSyntaxParser
import TestingExtensions

@testable import muterCore

final class SchemataBuilderTests: XCTestCase {
    func test_mutationSwitch() throws {
        let originalSyntax = try SyntaxParser.parse(source: "a != b").statements
        let schemataMutations = try makeSchemataMutations(["a >= b", "a <= b", "a == b"])

        let actualMutationSwitch = applyMutationSwitch(
            withOriginalSyntax: originalSyntax,
            and: schemataMutations
        )
        
        XCTAssertEqual(
            actualMutationSwitch.description,
            """
            if ProcessInfo.processInfo.environment[\"0\"] != nil {
              a >= b
            } else if ProcessInfo.processInfo.environment[\"2\"] != nil {
              a == b
            } else if ProcessInfo.processInfo.environment[\"1\"] != nil {
              a <= b
            } else {
              a != b
            }
            """
        )
    }

    private func makeSchemataMutations(_ mutations: [String]) throws -> [SchemataMutation] {
        try mutations
            .enumerated()
            .compactMap { (id: "\($0.offset)", source: try makeCodeBlock($0.element)) }
            .compactMap(SchemataMutation.init)
    }

    private func makeCodeBlock(_ source: String) throws -> CodeBlockItemListSyntax {
        try SyntaxParser.parse(source: source).statements
    }
}
