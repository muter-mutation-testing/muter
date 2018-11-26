import SwiftSyntax

class SourceCodeMutationSpy: Spy, SourceCodeMutation {
    
    private(set) var methodCalls: [String] = []
    private(set) var mutatedSources: [SourceFileSyntax] = []
    
    var canMutate: [Bool]!
    private var nextCanMutate = 0
    
    func canMutate(source: SourceFileSyntax) -> Bool {
        methodCalls.append(#function)
        
        let canMutate = self.canMutate[nextCanMutate] // This will intentionally overrun the array if you forget to specify the correct number of booleans
        nextCanMutate += 1
        
        return canMutate
    }
    
    func mutate(source: SourceFileSyntax) -> Syntax {
        methodCalls.append(#function)
        mutatedSources.append(source)
        return source
    }
}
