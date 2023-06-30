@testable import muterCore
import XCTest

final class DisableLintersRewriterTests: MuterTestCase {
    func test_disableLinters() throws {
        let code = try sourceCode(
            """
            // a comment
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

        let sut = DisableLintersRewriter().visit(code)

        XCTAssertEqual(
            sut.description,
            """
            // a comment
            // swiftformat:disable all
            // swiftlint:disable all

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
}
