import SwiftSyntax

extension ChangeLogicalConnectorOperator {
    class Rewriter: OperatorAwareRewriter {
        required init(positionToMutate: MutationPosition) {
            super.init(positionToMutate: positionToMutate)
            oppositeOperatorMapping = [
                "||": "&&",
                "&&": "||",
            ]
        }
    }
}
