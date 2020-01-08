import SwiftSyntax
import Foundation

enum RemoveSideEffectsOperator {
    class Visitor: SyntaxVisitor, PositionDiscoveringVisitor {
        var positionsOfToken = [AbsolutePosition]()
        private var concurencyPropertiesInFiles = [String]()
        private let concurrencyTypes = [
            "DispatchSemaphore",
            "NSRecursiveLock",
            "NSCondition",
            "NSConditionLock"
        ]

        let untestedFunctionNames: [String]

        init(configuration: MuterConfiguration) {
            untestedFunctionNames = ["print", "fatalError", "exit", "abort"] + configuration.excludeCallList
        }

        override func visit(_ node: PatternBindingListSyntax) {
            for statement in node where statementsContainsConcurrencyTypes(statement) {
                let property = propertyName(from: statement)
                concurencyPropertiesInFiles.append(property)
            }
        }
        
        override func visit(_ node: FunctionDeclSyntax) {
            guard let body = node.body else {
                return
            }

            for statement in body.statements where statementContainsMutableToken(statement) {
                let position = statement.endPosition
                positionsOfToken.append(position)
            }
        }

        private func statementContainsMutableToken(_ statement: CodeBlockItemListSyntaxIterator.Element) -> Bool {
            let doesntContainVariableAssignment = statement.children.count(variableAssignmentStatements) == 0
            let containsDiscardedResult = statement.description.contains("_ = ")

            let containsFunctionCall = statement.children
                .include(functionCallStatements)
                .exclude(untestedFunctionCallStatements)
                .count >= 1

            let doesntContainPossibleDeadlock = !statement.children
                .exclude(concurrencyStatements).isEmpty
            
            return doesntContainVariableAssignment &&
                doesntContainPossibleDeadlock && (containsDiscardedResult || containsFunctionCall)
        }

        private func variableAssignmentStatements(_ node: Syntax) -> Bool {
            return node is VariableDeclSyntax
        }

        private func functionCallStatements(_ node: Syntax) -> Bool {
            return node is FunctionCallExprSyntax
        }

        private func concurrencyStatements(_ node: Syntax) -> Bool {
            guard let functionCallSyntax = node as? FunctionCallExprSyntax,
                  let memberAccessSyntax = functionCallSyntax.calledExpression as? MemberAccessExprSyntax else {
                return false
            }

            let variable = memberAccessSyntax.base.description.trimmed

            return concurencyPropertiesInFiles.contains(variable)
        }

        private func untestedFunctionCallStatements(_ node: Syntax) -> Bool {
            return untestedFunctionNames.contains { name in node.description.contains(name) }
        }

        private func statementsContainsConcurrencyTypes(_ statement: PatternBindingSyntax) -> Bool {
            guard let functionCallSyntax = statement.initializer?.value as? FunctionCallExprSyntax else {
                return false
            }

            let expressionSyntax = functionCallSyntax.calledExpression

            return concurrencyTypes.contains(expressionSyntax.description.trimmed)
        }
        
        private func propertyName(from patternSyntax: PatternBindingSyntax) -> String {
            return patternSyntax.pattern.description.trimmed
        }
    }
}

extension RemoveSideEffectsOperator {
    class Rewriter: SyntaxRewriter, PositionSpecificRewriter {
        let positionToMutate: AbsolutePosition
        let description: String = "removed line"

        required init(positionToMutate: AbsolutePosition) {
            self.positionToMutate = positionToMutate
        }

        override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {

            guard let statements = node.body?.statements,
                let statementToExclude = statements.first(where: currentLineIsPositionToMutate) else {
                    return node
            }

            let mutatedFunctionStatements = statements.exclude { $0.description == statementToExclude.description }

            let newCodeBlockItemList = SyntaxFactory.makeCodeBlockItemList(mutatedFunctionStatements)
            let newFunctionBody = node.body!.withStatements(newCodeBlockItemList)

            return mutated(node, with: newFunctionBody)
        }

        private func currentLineIsPositionToMutate(_ currentStatement: CodeBlockItemSyntax) -> Bool {
            return currentStatement.endPosition.line == positionToMutate.line
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
