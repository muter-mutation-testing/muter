import SwiftSyntax

class OperatorAwareRewriter: SyntaxRewriter, PositionSpecificRewriter {
    let positionToMutate: MutationPosition
    var operatorSnapshot: MutationOperatorSnapshot = .null
    var currentExpression: String = ""
    
    var oppositeOperatorMapping: [String: String] = [:]
    
    required init(positionToMutate: MutationPosition) {
        self.positionToMutate = positionToMutate
    }

    override func visit(_ node: CodeBlockItemListSyntax) -> Syntax {
      return Syntax(node)
    }

    override func visit(_ token: TokenSyntax) -> Syntax {
        guard token.position == positionToMutate,
            let oppositeOperator = oppositeOperator(for: token.tokenKind) else {
                return Syntax(token)
        }

        operatorSnapshot = MutationOperatorSnapshot(
            before: token.description.trimmed,
            after: oppositeOperator,
            description: "changed \(token.description.trimmed) to \(oppositeOperator)"
        )

        let newToken = mutated(token, using: oppositeOperator)

//        recursion(token.parentCodeBlockItemList, target: token)

        let a = insertSchemataSwitch(
            at: token.parentCodeBlockItemList,
            transformedSyntax: token.parentCodeBlockItemList
        )

       let b = CodeBlockItemListSyntax.recursion(node: token.parentCodeBlockItemList._syntaxNode, find: token)?.description

        return a.newSyntax._syntaxNode//mutated(token, using: oppositeOperator)
    }
    
    private func oppositeOperator(for tokenKind: TokenKind) -> String? {
        guard case .spacedBinaryOperator(let `operator`) = tokenKind else {
            return nil
        }
        
        return oppositeOperatorMapping[`operator`]
    }
    
    private func mutated(_ token: TokenSyntax, using `operator`: String) -> Syntax {
        let tokenSyntax = SyntaxFactory.makeToken(
            .spacedBinaryOperator(`operator`),
            presence: .present,
            leadingTrivia: token.leadingTrivia,
            trailingTrivia: token.trailingTrivia
        )
        return Syntax(tokenSyntax)
    }
}

extension CodeBlockItemListSyntax {
    static func recursion<A: SyntaxProtocol>(node: Syntax, find: A) -> SyntaxProtocol? {
        print(node.syntaxNodeType)
        if node.endPosition == find.endPosition {
            return node.as(A.self)
        }

        if node.children.isEmpty {
            return node
        }

        let childNode = node.children.first!
        for child in node.children {
            return recursion(node: child, find: find)
        }

        return recursion(node: childNode, find: find)
    }
}

func recursion(_ node: SyntaxProtocol, target: SyntaxProtocol, replaceWith newSyntax: SyntaxProtocol) {
//    print(node.syntaxNodeType)
//    print(node.endPosition)
//
//    if node.endPosition == target.endPosition {
//        if node.hasParent {
//            node.parent!._syntaxNode.
//        }
//    }
//
//    for child in node.children {
//        recursion(child, target: target, replaceWith: newSyntax)
//    }
}

extension SyntaxProtocol {
    var parentCodeBlockItemList: CodeBlockItemListSyntax {
        guard !_syntaxNode.is(CodeBlockItemListSyntax.self) else {
            return _syntaxNode.as(CodeBlockItemListSyntax.self)!
        }

        guard parent != nil, !parent!.is(CodeBlockItemListSyntax.self) else {
            return parent!.as(CodeBlockItemListSyntax.self)!
        }
        var parent: Syntax? = self.parent
        while let theParent = parent {
            if theParent.is(CodeBlockItemListSyntax.self) {
                return theParent.as(CodeBlockItemListSyntax.self)!

            }

            parent = theParent.parent
        }

        return SyntaxFactory.makeCodeBlockItemList([])
    }
}
