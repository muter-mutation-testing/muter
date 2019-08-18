import SwiftSyntax

class InstrumentationVisitor: SyntaxRewriter {
    private let instrumentation: (String) -> CodeBlockItemSyntax
    private(set) var instrumentedFunctions: [String] = []
    private var typeNameStack: [String] = []
    
    init(instrumentation: @escaping (String) -> CodeBlockItemSyntax) {
        self.instrumentation = instrumentation
    }
    
    override func visitPost(_ node: Syntax) {
        switch node {
        case is StructDeclSyntax,
             is EnumDeclSyntax,
             is ClassDeclSyntax,
             is ExtensionDeclSyntax:
            _ = typeNameStack.popLast()
        default:
            break
        }
    }
    
    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        typeNameStack.append(node.identifier.text.trimmed)
        return super.visit(node)
    }
    
    override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
        typeNameStack.append(node.identifier.text.trimmed)
        return super.visit(node)
    }
    
    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        typeNameStack.append(node.identifier.text.trimmed)
        return super.visit(node)
    }
    
    override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
        typeNameStack.append(node.extendedType.description.trimmed)
        return super.visit(node)
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        guard let existingBody = node.body,
            case let existingStatements = existingBody.statements else {
            
            return super.visit(node)
        }
        
        let functionName = fullyQualifiedFunctionName(for: node)
        instrumentedFunctions.append(functionName)
        
        return node.withBody(
            existingBody.withStatements(
                existingStatements
                    .inserting(instrumentation(functionName), at: 0)
        ))
    }
    
    private func fullyQualifiedFunctionName(for node: FunctionDeclSyntax) -> String {
        let typeName = typeNameStack.accumulate(into: "") {
            $0.isEmpty ?
                $1 + "." :
                $0 + "\($1)."
        }
        return (typeName +
            node.identifier.description +
            node.signature.description).trimmed
    }
}

extension InstrumentationVisitor {
    static let `default`: (String) -> CodeBlockItemSyntax = { functionName in

        let instrumentationFunctionName = "CodeCoverageInstrumenter.shared.recordFunctionCall"
        return SyntaxFactory
            .makeBlankCodeBlockItem()
            .withItem(SyntaxFactory.makeTokenList([
                SyntaxFactory.makeIdentifier("\(instrumentationFunctionName)").withLeadingTrivia([.newlines(1)]),
                SyntaxFactory.makeLeftParenToken(),
                SyntaxFactory.makeIdentifier("forFunctionNamed"),
                SyntaxFactory.makeColonToken().withTrailingTrivia(.spaces(1)),
                SyntaxFactory.makeStringQuoteToken(),
                SyntaxFactory.makeIdentifier("\(functionName)"),
                SyntaxFactory.makeStringQuoteToken(),
                SyntaxFactory.makeRightParenToken(),
            ]))

    }

}
