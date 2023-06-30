import SwiftSyntax

enum ChangeLogicalConnectorOperator {
    class Visitor: TokenAwareVisitor {
        convenience init(
            configuration: MuterConfiguration? = nil,
            sourceFileInfo: SourceFileInfo
        ) {
            self.init(
                configuration: configuration,
                sourceFileInfo: sourceFileInfo,
                mutationOperatorId: .logicalOperator
            )

            tokensToDiscover = [
                .spacedBinaryOperator("||"),
                .spacedBinaryOperator("&&"),
            ]

            oppositeOperatorMapping = [
                "||": "&&",
                "&&": "||",
            ]
        }
    }
}
