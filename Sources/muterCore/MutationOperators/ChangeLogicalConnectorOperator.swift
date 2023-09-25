import SwiftSyntax

enum ChangeLogicalConnectorOperator {
    class Visitor: TokenAwareVisitor {
        convenience init(
            configuration: MuterConfiguration? = nil,
            sourceCodeInfo: SourceCodeInfo
        ) {
            self.init(
                configuration: configuration,
                sourceCodeInfo: sourceCodeInfo,
                mutationOperatorId: .logicalOperator
            )

            tokensToDiscover = [
                .binaryOperator("||"),
                .binaryOperator("&&"),
            ]

            oppositeOperatorMapping = [
                "||": "&&",
                "&&": "||",
            ]
        }
    }
}
