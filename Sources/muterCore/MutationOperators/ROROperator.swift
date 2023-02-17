import SwiftSyntax

enum ROROperator {
    class Rewriter: OperatorAwareRewriter {
        required init(positionToMutate: MutationPosition) {
            super.init(positionToMutate: positionToMutate)
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

    class Visitor: TokenAwareVisitor {
        required init(configuration: MuterConfiguration? = nil, sourceFileInfo: SourceFileInfo) {
            super.init(configuration: configuration, sourceFileInfo: sourceFileInfo)
            tokensToDiscover = [
                .spacedBinaryOperator("=="),
                .spacedBinaryOperator("!="),
                .spacedBinaryOperator(">="),
                .spacedBinaryOperator("<="),
                .spacedBinaryOperator("<"),
                .spacedBinaryOperator(">"),
            ]
        }
    }

    class SchemataVisitor: TokenAwareSchemataVisitor {
        convenience init(
            configuration: MuterConfiguration? = nil,
            sourceFileInfo: SourceFileInfo
        ) {
            self.init(
                configuration: configuration,
                sourceFileInfo: sourceFileInfo,
                mutationOperatorId: .ror
            )

            tokensToDiscover = [
                .spacedBinaryOperator("=="),
                .spacedBinaryOperator("!="),
                .spacedBinaryOperator(">="),
                .spacedBinaryOperator("<="),
                .spacedBinaryOperator("<"),
                .spacedBinaryOperator(">"),
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
