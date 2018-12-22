import SwiftSyntax
@testable import muterCore

class SourceCodeMutationSpy: Spy, SourceCodeMutation {
    
    private(set) var methodCalls: [String] = []
    
    var filePath: String = ""
    var sourceCode: SourceFileSyntax = SyntaxFactory.makeBlankSourceFile()
    var rewriter: PositionSpecificRewriter = NegateConditionalsMutation.Rewriter(positionToMutate: .firstPosition)
    func mutate() {
        methodCalls.append(#function)
    }
}
