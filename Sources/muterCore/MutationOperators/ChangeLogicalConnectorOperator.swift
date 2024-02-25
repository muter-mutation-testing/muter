import SwiftSyntax

enum ChangeLogicalConnectorOperator {
    class Visitor: TokenAwareVisitor {
        convenience init(
            configuration: MuterConfiguration? = nil,
            sourceCodeInfo: SourceCodeInfo,
            regionsWithoutCoverage: [Region] = []
        ) {
            self.init(
                configuration: configuration,
                sourceCodeInfo: sourceCodeInfo,
                mutationOperatorId: .logicalOperator,
                regionsWithoutCoverage: regionsWithoutCoverage
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
