import SwiftSyntax

enum ROROperator {
    class Visitor: TokenAwareVisitor {
        convenience init(
            configuration: MuterConfiguration? = nil,
            sourceCodeInfo: SourceCodeInfo,
            regionsWithoutCoverage: [Region] = []
        ) {
            self.init(
                configuration: configuration,
                sourceCodeInfo: sourceCodeInfo,
                mutationOperatorId: .ror,
                regionsWithoutCoverage: regionsWithoutCoverage
            )

            tokensToDiscover = [
                .binaryOperator("=="),
                .binaryOperator("!="),
                .binaryOperator(">="),
                .binaryOperator("<="),
                .binaryOperator("<"),
                .binaryOperator(">"),
            ]

            // Each comparison becomes its negation (#143). `a > b` becomes `a <= b`, not `a < b`:
            // the opposite direction would leave the case where both values are equal unchanged,
            // so tests that never check that boundary would not notice the mutant.
            oppositeOperatorMapping = [
                "==": "!=",
                "!=": "==",
                ">=": "<",
                "<=": ">",
                ">": "<=",
                "<": ">=",
            ]
        }
    }
}
