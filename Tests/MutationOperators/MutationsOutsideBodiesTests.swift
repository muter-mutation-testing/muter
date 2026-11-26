@testable import muterCore
import SwiftSyntax
import TestingExtensions
import XCTest

/// A mutant wraps its statement list in `if … else`. Outside a function, closure, accessor or
/// switch-case body that list is the top level of the file, where wrapping a type declaration or a
/// stored property does not compile. So no operator mutates code outside a body.
final class MutationsOutsideBodiesTests: MuterTestCase {
    private let source = """
    struct Person {
        let age: Int
        static let limit = 18 == 18
        static let label = true ? "adult" : "child"
        var isAdult: Bool { age >= 18 }
        func greet(formal: Bool = true && false) -> String {
            formal ? "Good day" : "Hi"
        }
    }
    """

    private func mutants(_ id: MutationOperator.Id) throws -> [String] {
        let code = try sourceCode(source)
        let visitor = id.visitor(nil, SourceCodeInfo(path: "/path/to/file", code: code), [])
        visitor.walk(code)
        return visitor.schemataMappings.mutationSchemata.map { "\($0.position.line): \($0.snapshot.description)" }
    }

    func test_relationalOperatorReplacement_onlyInsideBodies() throws {
        // `18 == 18` is a stored property: not mutated. `age >= 18` is in a computed property's accessor.
        XCTAssertEqual(try mutants(.ror), ["5: changed >= to <="])
    }

    func test_changeLogicalConnector_notInDefaultParameterValues() throws {
        XCTAssertEqual(try mutants(.logicalOperator), [])
    }

    func test_swapTernary_onlyInsideBodies() throws {
        // The ternary in `label` is a stored property: not mutated. The one in greet(formal:) is.
        XCTAssertEqual(try mutants(.swapTernary), ["7: swapped ternary operator"])
    }
}
