import SwiftSyntax

struct Id<Value: Hashable & Equatable>: Hashable, Equatable {
    let value: Value
}

class CodeCoverageInstrumenter {
    static let shared = CodeCoverageInstrumenter(functionIds: Set<Id<Int>>())
    private(set) var functionCallCounts: Dictionary<Id<Int>, Int>
    
    init(functionIds: Set<Id<Int>>) {
        functionCallCounts = Dictionary<Id<Int>, Int>(minimumCapacity: functionIds.count)
        for id in functionIds {
            functionCallCounts[id] = 0
        }
    }
    
    func recordFunctionInvocation(with id: Id<Int>) {
        fatalError("wow this feels dirty")
    }
    
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
