import SwiftSyntax
import Foundation

enum RemoveSideEffectsOperator {
    class Visitor: SyntaxVisitor, PositionDiscoveringVisitor {
        private(set) var positionsOfToken = [AbsolutePosition]()

        override func visit(_ node: CodeBlockItemSyntax) {
            super.visit(node)

            for statement in node.children where statementCanBeMutated(statement) {
                let position = statement.endPosition
                positionsOfToken.append(position)
            }
        }

        override func visit(_ node: TryExprSyntax) {
            super.visit(node)

            if containsMemberAccess(node) {
                let position = node.position
                positionsOfToken.append(position)
            }
        }

        override func visit(_ node: DiscardAssignmentExprSyntax) {
            let position = node.endPosition
            positionsOfToken.append(position)
        }
    }
}

private extension RemoveSideEffectsOperator.Visitor {
    func statementCanBeMutated(_ statement: Syntax) -> Bool {
        return statementIsNotFunctionDeclaration(statement) &&
            statementContainsVoidFunctionCall(statement)
    }

    func statementIsNotFunctionDeclaration(_ statement: Syntax) -> Bool {
        return !(statement is FunctionDeclSyntax)
    }

    func statementContainsVoidFunctionCall(_ statement: Syntax) -> Bool {
        if isSpecialFunctionCall(statement) {
            return false
        }

        let doesntContainVariableAssignment = statement.children.count(variableAssignmentStatements) == 0
        let containsFunctionCall = statement.children.count(functionCallStatements) > 0
        let doesntContainReturnStatement = statement.children.count(returnStatements) == 0
        return doesntContainReturnStatement &&
            doesntContainVariableAssignment &&
            (containsFunctionCall || containsMemberAccess(statement))
    }

    func returnStatements(_ node: Syntax) -> Bool {
        return node.description.contains("return")
    }

    func variableAssignmentStatements(_ node: Syntax) -> Bool {
        return node is VariableDeclSyntax
    }

    func functionCallStatements(_ node: Syntax) -> Bool {
        return node is FunctionCallArgumentListSyntax || node is FunctionCallExprSyntax
    }

    func isSpecialFunctionCall(_ node: Syntax) -> Bool {
        return node.description.contains("print") ||
            node.description.contains("fatalError") ||
            node.description.contains("exit") ||
            node.description.contains("abort")
    }

    func containsMemberAccess(_ node: Syntax) -> Bool {
        return node.children.contains { $0 is MemberAccessExprSyntax} &&
            node.children.contains { $0 is FunctionCallArgumentListSyntax}
    }
}

extension RemoveSideEffectsOperator {
    class Rewriter: SyntaxRewriter, PositionSpecificRewriter {
        let positionToMutate: AbsolutePosition

        required init(positionToMutate: AbsolutePosition) {
            self.positionToMutate = positionToMutate
        }

        override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
            // parse every line of the declaration into a mapping of the line number to the statements on that line
            // remove the statements that match the line we need to mutate
            // generate and return a new function declaration that has the lines excluded

            var items: [Syntax] = []
            for item in node.body!.statements
                .map({ $0.item }) {
                    items += flatten(item.children)
            }
            
            let result = items.exclude { $0.endPosition.line == positionToMutate.line }.map { SyntaxFactory.makeCodeBlockItem(item: $0, semicolon: nil)}
            let body = SyntaxFactory.makeCodeBlock(leftBrace: node.body!.leftBrace,
                                        statements: SyntaxFactory.makeCodeBlockItemList(result),
                                        rightBrace: node.body!.rightBrace)
            
            return mutated(node, with: body)
        }
        
        func flatten(_ node: SyntaxChildren) -> [Syntax] {
            
            return node.accumulate(into: []) { result, childNode in
                if childNode.numberOfChildren == 0 {
                    return [childNode] + result
                }
                return flatten(childNode.children) + result
            }
        }
        
        private func mutated(_ node: FunctionDeclSyntax, with body: CodeBlockSyntax) -> DeclSyntax {
            return SyntaxFactory.makeFunctionDecl(attributes: node.attributes,
                                                  modifiers: node.modifiers,
                                                  funcKeyword: node.funcKeyword,
                                                  identifier: node.identifier,
                                                  genericParameterClause: node.genericParameterClause,
                                                  signature: node.signature,
                                                  genericWhereClause: node.genericWhereClause,
                                                  body: body)
        }
    }
}
