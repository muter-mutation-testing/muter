import SwiftSyntax

class SourceCodeMutationSpy: Spy, SourceCodeMutation {
    
    private(set) var methodCalls: [String] = []
    private(set) var mutatedSources: [SourceFileSyntax] = []
    
    var canMutate: [Bool]!
    private var canMutateIndex = 0
    
    func canMutate(source: SourceFileSyntax) -> Bool {
        methodCalls.append(#function)
        
        let canMutate = self.canMutate[canMutateIndex] // This will intentionally overrun the array if you forget to specify the correct number of booleans
        canMutateIndex += 1
        
        return canMutate
    }
    
    func mutate(source: SourceFileSyntax) -> Syntax {
        methodCalls.append(#function)
        mutatedSources.append(source)
        return source
    }
}
