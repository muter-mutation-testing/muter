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
    }
}
