@testable import muterCore
import TestingExtensions
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

        let sut = DisableLintersRewriter().rewrite(code)
        AssertSnapshot(formatCode(sut.description))
    }
}
