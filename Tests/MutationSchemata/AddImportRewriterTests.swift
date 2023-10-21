@testable import muterCore
import TestingExtensions
import XCTest

final class AddImportRewriterTests: MuterTestCase {
    func test_addImport() throws {
        let code = try sourceCode(
            """
            #if os(iOS) || os(tvOS)
                import Foo
            #else
                import Bar
            #endif

            func foo() {
              return true && false
            }
            """
        )

        let sut = AddImportRewriter().rewrite(code)

        AssertSnapshot(sut.description)
    }

    func test_doNotAddImport() throws {
        let code = try sourceCode(
            """
            #if os(iOS) || os(tvOS)
                import Foo
            #else
                import Bar
            #endif
            import Foundation

            func foo() {
              return true && false
            }
            """
        )

        let sut = AddImportRewriter().visit(code)
        AssertSnapshot(sut.description)
    }
}
