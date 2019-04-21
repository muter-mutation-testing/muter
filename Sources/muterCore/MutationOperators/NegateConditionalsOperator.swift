import SwiftSyntax

extension NegateConditionalsOperator {
    class Rewriter: OperatorAwareRewriter {
        required init(positionToMutate: AbsolutePosition) {
            super.init(positionToMutate: positionToMutate)
            oppositeOperatorMapping = [
                "==": "!=",
                "!=": "==",
                ">=": "<=",
                "<=": ">=",
                ">": "<",
                "<": ">"
            ]
        }
    }
}
