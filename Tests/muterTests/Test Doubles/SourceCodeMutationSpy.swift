import SwiftSyntax

class SourceCodeMutationSpy: Spy, SourceCodeMutation {
    private(set) var methodCalls: [String] = []
    private(set) var sources: [SourceFileSyntax] = []
    
    func mutate(source: SourceFileSyntax) -> Syntax {
        methodCalls.append(#function)
        sources.append(source)
        return source
    }
}
