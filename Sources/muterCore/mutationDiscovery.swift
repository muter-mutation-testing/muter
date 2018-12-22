import SwiftSyntax

func filePathsToIntermediateValues(filePath: String) -> ([AbsolutePosition], SourceFileSyntax, String)? {
    guard let source = sourceCode(fromFileAt: filePath) else {
        return nil
    }
    
    let visitor = NegateConditionalsMutation.Visitor()
    visitor.visit(source)
    
    return (visitor.positionsOfToken, source, filePath)
}

func intermediateValuesToMutations(values: (positions: [AbsolutePosition], sourceCode: SourceFileSyntax, filePath: String)) -> [NegateConditionalsMutation] {
    return values.positions.map { position in
        return NegateConditionalsMutation(filePath: values.filePath,
                                          sourceCode: values.sourceCode,
                                          rewriter: NegateConditionalsMutation.Rewriter(positionToMutate: position),
                                          delegate: NegateConditionalsMutation.Delegate())
        
    }
}

func discoverMutations(inFilesAt filePaths: [String]) -> [NegateConditionalsMutation] {
    return filePaths
        .compactMap(filePathsToIntermediateValues)
        .flatMap(intermediateValuesToMutations)
}
