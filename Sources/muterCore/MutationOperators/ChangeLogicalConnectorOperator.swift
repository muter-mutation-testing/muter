import SwiftSyntax

enum ChangeLogicalConnectorOperator {
    class Rewriter: OperatorAwareRewriter {
        required init(positionToMutate: MutationPosition) {
            super.init(positionToMutate: positionToMutate)
            oppositeOperatorMapping = [
                "||": "&&",
                "&&": "||",
            ]
        }
    }

    class Visitor: TokenAwareVisitor {
        required init(configuration: MuterConfiguration? = nil, sourceFileInfo: SourceFileInfo) {
            super.init(configuration: configuration, sourceFileInfo: sourceFileInfo)
            tokensToDiscover = [
                .spacedBinaryOperator("||"),
                .spacedBinaryOperator("&&"),
            ]
        }
    }
    
    class SchemataVisitor: TokenAwareSchemataVisitor {
        required init(
            configuration: MuterConfiguration? = nil,
            sourceFileInfo: SourceFileInfo
        ) {
            super.init(
                configuration: configuration,
                sourceFileInfo: sourceFileInfo
            )

            schemataMappings = SchemataMutationMapping(
                filePath: sourceFileInfo.path,
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
