import SwiftSyntax
@testable import muterCore

class SourceCodeMutationSpy: Spy, SourceCodeMutation {
    
    private(set) var methodCalls: [String] = []
    
    let filePath: String = "a file path"
    let sourceCode: SourceFileSyntax = SyntaxFactory.makeBlankSourceFile()
    let rewriter: PositionSpecificRewriter = NegateConditionalsMutation.Rewriter(positionToMutate: .firstPosition)

    func mutate() {
        methodCalls.append(#function)
    }
}
