import SwiftSyntax

class TokenAwareVisitor: SyntaxAnyVisitor, PositionDiscoveringVisitor {
    var oppositeOperatorMapping: [String: String] = [:]

    fileprivate(set) var tokensToDiscover = [TokenKind]()

    private(set) var positionsOfToken = [MutationPosition]()
    private(set) var schematas = [CodeBlockItemListSyntax: [Schemata]]()

    private let sourceFileInfo: SourceFileInfo

    required init(configuration: MuterConfiguration?, sourceFileInfo: SourceFileInfo) {
        self.sourceFileInfo = sourceFileInfo
    }
    
    override func visitAny(_ node: Syntax) -> SyntaxVisitorContinueKind {
        node.as(TokenSyntax.self).map { node in
            if canMutateToken(node),
               let oppositeOperator = oppositeOperator(for: node.tokenKind) {

                let mutation = Schemata(
                    id: makeSchemataId(sourceFileInfo, node),
                    syntaxMutation: transform(
                        node: node,
                        mutatedSyntax: mutated(node, using: oppositeOperator)
                    ),
                    positionInSourceCode: node.mutationPosition(with: sourceFileInfo),
                    snapshot: MutationOperatorSnapshot(
                        before: node.description.trimmed,
                        after: oppositeOperator,
                        description: "changed \(node.description.trimmed) to \(oppositeOperator)"
                    )
                )

                schematas[node.codeBlockItemListSyntax, default: []].append(mutation)
            }
        }
        
        return .visitChildren
    }
    
    override func visit(_ node: SequenceExprSyntax) -> SyntaxVisitorContinueKind {
        node.isInsideCompilerDirective
            ? .skipChildren
            : .visitChildren
    }

    private func canMutateToken(_ token: TokenSyntax) -> Bool {
        tokensToDiscover.contains(token.tokenKind) &&
        token.parent?.is(BinaryOperatorExprSyntax.self) == true
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

private extension SequenceExprSyntax {
    var isInsideCompilerDirective: Bool {
        parent?.is(IfConfigClauseSyntax.self) == true
    }
}

/// Relational Operator Replacement
enum ROROperator {
    class Visitor: TokenAwareVisitor {
        required init(configuration: MuterConfiguration? = nil, sourceFileInfo: SourceFileInfo) {
            super.init(configuration: configuration, sourceFileInfo: sourceFileInfo)
            tokensToDiscover = [
                .spacedBinaryOperator("=="),
                .spacedBinaryOperator("!="),
                .spacedBinaryOperator(">="),
                .spacedBinaryOperator("<="),
                .spacedBinaryOperator("<"),
                .spacedBinaryOperator(">"),
            ]

            oppositeOperatorMapping = [
                "==": "!=",
                "!=": "==",
                ">=": "<=",
                "<=": ">=",
                ">": "<",
                "<": ">",
            ]
        }
    }
}

enum ChangeLogicalConnectorOperator {
    class Visitor: TokenAwareVisitor {
        required init(configuration: MuterConfiguration? = nil, sourceFileInfo: SourceFileInfo) {
            super.init(configuration: configuration, sourceFileInfo: sourceFileInfo)
            tokensToDiscover = [
                .spacedBinaryOperator("||"),
                .spacedBinaryOperator("&&"),
            ]

            oppositeOperatorMapping = [
                "||": "&&",
                "&&": "||",
            ]
        }
    }
}
