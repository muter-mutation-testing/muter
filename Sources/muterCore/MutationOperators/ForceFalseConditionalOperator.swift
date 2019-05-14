import SwiftSyntax

extension ForceFalseConditionalOperator {
    class Rewriter: OperatorAwareRewriter {
        required init(positionToMutate: AbsolutePosition) {
            super.init(positionToMutate: positionToMutate)
            oppositeOperatorMapping = [
                "if": "if false &&"
            ]
        }
    }
}
