import SwiftSyntax

struct Id<Value: Hashable & Equatable>: Hashable, Equatable {
    let value: Value
}

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
