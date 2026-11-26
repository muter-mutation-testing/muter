@testable import muterCore
import SwiftSyntax
import TestingExtensions
import XCTest

final class SwapBooleanLiteralOperatorTests: MuterTestCase {
    private func visit(_ code: String) throws -> (visitor: SwapBooleanLiteralOperator.Visitor, source: SourceFileSyntax) {
        let source = try sourceCode(code)
        let visitor = SwapBooleanLiteralOperator.Visitor(
            sourceCodeInfo: SourceCodeInfo(path: "/path/to/file", code: source)
        )
        visitor.walk(source)
        return (visitor, source)
    }

    func test_swapsLiteralsInsideFunctionAndClosureBodies() throws {
        let (visitor, _) = try visit("""
        func enableSync(_ settings: Settings) {
            settings.isSyncEnabled = true
            settings.update(flag: false)
            [1, 2].forEach { _ in settings.isDirty = true }
        }
        """)

        let snapshots = visitor.schemataMappings.mutationSchemata.map(\.snapshot)
        XCTAssertEqual(snapshots.map(\.description).sorted(), [
            "changed false to true",
            "changed true to false",
            "changed true to false",
        ])
    }

    func test_doesNotSwapLiteralsOutsideABody() throws {
        // A mutant wraps the statement list in `if … else`, which does not compile at the top level
        // of a file or around a type member.
        let (visitor, _) = try visit("""
        let isTopLevel = true

        struct Settings {
            var isSyncEnabled = false
            func update(flag: Bool = true) {}
        }

        func check() {
            #if true
            print("compiled")
            #endif
        }
        """)

        XCTAssertTrue(visitor.schemataMappings.mutationSchemata.isEmpty)
    }

    func test_insideAFileWideIfConfig_onlyLiteralsInBodiesAreSwapped() throws {
        // Many files wrap all their code in `#if os(…)`. A default parameter value there is not in a body.
        let (visitor, _) = try visit("""
        #if os(iOS) || os(macOS)
        struct Inspector {
            var isVerbose = false
            func features(includeIdentifiers: Bool = false) -> Bool {
                #if DEBUG
                return true
                #else
                return includeIdentifiers
                #endif
            }
        }
        #endif
        """)

        XCTAssertEqual(
            visitor.schemataMappings.mutationSchemata.map(\.snapshot.description),
            ["changed true to false"]
        )
    }

    func test_eachMutantChangesOnlyItsOwnLiteral() throws {
        let (visitor, source) = try visit("""
        func both() -> Bool {
            return false && false
        }
        """)

        let rewritten = MuterRewriter(visitor.schemataMappings).rewrite(source).description

        XCTAssertEqual(visitor.schemataMappings.mutationSchemata.count, 2)
        XCTAssertTrue(rewritten.contains("return true && false"), rewritten)
        XCTAssertTrue(rewritten.contains("return false && true"), rewritten)
    }
}
