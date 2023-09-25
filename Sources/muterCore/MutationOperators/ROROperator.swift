import SwiftSyntax

enum ROROperator {
    class Visitor: TokenAwareVisitor {
        convenience init(
            configuration: MuterConfiguration? = nil,
            sourceCodeInfo: SourceCodeInfo
        ) {
            self.init(
                configuration: configuration,
                sourceCodeInfo: sourceCodeInfo,
                mutationOperatorId: .ror
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
