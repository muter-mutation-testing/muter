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

            oppositeOperatorMapping = [
                "==": "!=",
                "!=": "==",
                ">=": "<=",
                "<=": ">=",
                ">": "<",
                "<": ">",
            ]
        }
    }
}
