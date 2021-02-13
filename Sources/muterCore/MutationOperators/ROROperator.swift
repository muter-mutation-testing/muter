import SwiftSyntax

extension ROROperator {
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
}
