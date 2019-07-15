import SwiftSyntax

extension ChangeLogicalConnectorOperator {
    class Rewriter: OperatorAwareRewriter {
        required init(positionToMutate: AbsolutePosition) {
            super.init(positionToMutate: positionToMutate)
            oppositeOperatorMapping = [
                "||": "&&",
                "&&": "||",
            ]
        }
    }
}
