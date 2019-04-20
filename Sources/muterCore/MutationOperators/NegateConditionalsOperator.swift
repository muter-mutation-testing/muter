import SwiftSyntax

extension NegateConditionalsOperator {
    class Rewriter: TokenAwareRewriter {
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
