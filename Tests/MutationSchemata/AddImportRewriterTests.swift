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
            import class Foundation.URL

            func foo() {
              return true && false
            }
            """
        )

        let sut = AddImportRewriter().rewrite(code)

        AssertSnapshot(formatCode(sut.description))
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
        AssertSnapshot(formatCode(sut.description))
    }
}
