import XCTest
import SwiftSyntax
import SwiftSyntaxParser
import TestingExtensions

@testable import muterCore

final class SchemataBuilderTests: XCTestCase {
    func test_schemataMerging() throws {
        let codeBlock = try sourceCode("return 1").statements

        let x = SchemataMutationMapping()
        x.add(codeBlock, try .make())
        x.add(codeBlock, try .make())
        
        let y = SchemataMutationMapping()
        y.add(codeBlock, try .make())
        y.add(codeBlock, try .make())
        
        let actualMappings = x + y
        
        XCTAssertEqual(actualMappings.codeBlocks, ["return 1"])
        XCTAssertEqual(actualMappings.schematas.count, 4)
    }
    
    func test_mutationSwitch() throws {
        let originalSyntax = try sourceCode("\n  a != b\n").statements
        let schemataMutations = try makeSchemataMutations([
            "\n  a >= b\n",
            "\n  a <= b\n",
            "\n  a == b\n"
        ])

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
    
    func test_mutationsThatRequiredImplicitReturn() throws {
        let originalSyntax = try sourceCode("\n  a != b\n").statements
        let schemataMutations = try makeSchemataMutations([
            "\n  a >= b\n",
            "\n  a <= b\n",
            "\n  a == b\n"
        ])

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

    private func makeSchemataMutations(_ mutations: [String]) throws -> [Schemata] {
        try mutations
            .enumerated()
            .compactMap { try Schemata.make(id: "\($0.offset)", syntaxMutation: $0.element) }
    }
}
