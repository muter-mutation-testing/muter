import XCTest

@testable import muterCore

final class AddImportRewriterTests: XCTestCase {
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

        let sut = AddImportRewriter().visit(code)
        
        XCTAssertEqual(
            sut.description,
            """
            import Foundation

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
        
        XCTAssertEqual(
            sut.description,
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
    }
}
