import SwiftSyntax

/// Swaps the closed range operator `...` and the half-open range operator `..<` (#146).
/// An off-by-one at the end of a range is a common mistake, and tests that never reach the last
/// element do not notice it.
enum SwapRangeOperator {
    final class Visitor: TokenAwareVisitor {
        convenience init(
            configuration: MuterConfiguration? = nil,
            sourceCodeInfo: SourceCodeInfo,
            regionsWithoutCoverage: [Region] = []
        ) {
            self.init(
                configuration: configuration,
                sourceCodeInfo: sourceCodeInfo,
                mutationOperatorId: .swapRangeOperator,
                regionsWithoutCoverage: regionsWithoutCoverage
            )

            tokensToDiscover = [
                .binaryOperator("..."),
                .binaryOperator("..<"),
            ]

            oppositeOperatorMapping = [
                "...": "..<",
                "..<": "...",
            ]
        }

        /// Only ranges inside a body: a range in a stored property or a default parameter value
        /// would be wrapped in an `if` at the top level of the file, which does not compile.
        override func visit(_ node: BinaryOperatorExprSyntax) -> SyntaxVisitorContinueKind {
            guard node.isInsideABody else {
                return .visitChildren
            }

            return super.visit(node)
        }
    }
}
