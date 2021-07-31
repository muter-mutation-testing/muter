import SwiftSyntax
import Foundation

enum RemoveSideEffectsOperator {
    final class Visitor: SyntaxAnyVisitor, PositionDiscoveringVisitor {
        var positionsOfToken = [MutationPosition]()
        private var concurrencyPropertiesInFile = [String]()
        private let concurrencyTypes = [
            "DispatchSemaphore",
            "NSRecursiveLock",
            "NSCondition",
            "NSConditionLock",
        ]

        private let untestedFunctionNames: [String]
        private let sourceFileInfo: SourceFileInfo

        init(configuration: MuterConfiguration? = nil, sourceFileInfo: SourceFileInfo) {
            untestedFunctionNames = ["print", "fatalError", "exit", "abort"] + (configuration?.excludeCallList ?? [])
            self.sourceFileInfo = sourceFileInfo
        }

        override func visit(_ node: PatternBindingListSyntax) -> SyntaxVisitorContinueKind {
            for statement in node where statementsContainsConcurrencyTypes(statement) {
                let property = propertyName(from: statement)
                concurrencyPropertiesInFile.append(property)
            }

            return super.visit(node)
        }

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            guard let body = node.body, !node.hasImplicitReturn() else {
                return super.visit(node)
            }

            for statement in body.statements where statementContainsMutableToken(statement) {
                let sourceLocation = statement.endLocation(
                    converter: SourceLocationConverter(
                        file: sourceFileInfo.path,
                        source: sourceFileInfo.source
                    ),
                    afterTrailingTrivia: true
                )

                positionsOfToken.append(
                    MutationPosition(
                        sourceLocation: sourceLocation
                    )
                )
            }

            return super.visit(node)
        }

        private func statementContainsMutableToken(_ statement: CodeBlockItemListSyntax.Element) -> Bool {
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
            return node.is(VariableDeclSyntax.self)
        }

        private func functionCallStatements(_ node: Syntax) -> Bool {
            return node.is(FunctionCallExprSyntax.self)
        }

        private func concurrencyStatements(_ node: Syntax) -> Bool {
            guard let functionCallSyntax = node.as(FunctionCallExprSyntax.self),
                  let calledExpression = functionCallSyntax.calledExpression.as(MemberAccessExprSyntax.self),
                  let variableName = calledExpression.base?.description.trimmed else {
                return false
            }

            return concurrencyPropertiesInFile.contains(variableName)
        }

        private func untestedFunctionCallStatements(_ node: Syntax) -> Bool {
            return untestedFunctionNames.contains { name in node.description.contains(name) }
        }

        private func statementsContainsConcurrencyTypes(_ statement: PatternBindingSyntax) -> Bool {
            guard let functionCallSyntax = statement.initializer?.value.as(FunctionCallExprSyntax.self) else {
                return false
            }

            let expressionSyntax = functionCallSyntax.calledExpression

            return concurrencyTypes.contains(expressionSyntax.description.trimmed)
        }

        private func propertyName(from patternSyntax: PatternBindingSyntax) -> String {
            patternSyntax.pattern.description.trimmed
        }
    }
}

private extension FunctionDeclSyntax {
    func hasImplicitReturn() -> Bool {
        guard let body = body else {
            return false
        }
        
        return body.statements.count == 1 &&
            signature.output != nil &&
            signature.output?.isReturningVoid == false
    }
}

private extension ReturnClauseSyntax {
    var isReturningVoid: Bool {
        ["Void", "()"].contains(returnType.withoutTrivia().description.trimmed)
    }
}

private extension SyntaxProtocol {
    func withoutTrivia() -> Self {
        withoutLeadingTrivia().withoutTrailingTrivia()
    }
}

extension RemoveSideEffectsOperator {
    class Rewriter: SyntaxRewriter, PositionSpecificRewriter {
        let positionToMutate: MutationPosition
        var operatorSnapshot: MutationOperatorSnapshot = .null

        required init(positionToMutate: MutationPosition) {
            self.positionToMutate = positionToMutate
        }

        override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
            guard
                let statements = node.body?.statements,
                let statementToExclude = statements.first(where: currentLineIsPositionToMutate)
            else { return DeclSyntax(node) }

            let mutatedFunctionStatements = statements.exclude { $0.description == statementToExclude.description }

            let newCodeBlockItemList = SyntaxFactory.makeCodeBlockItemList(mutatedFunctionStatements)
            let newFunctionBody = node.body!.withStatements(newCodeBlockItemList)

            operatorSnapshot = MutationOperatorSnapshot(
                before: statementToExclude.description.trimmed.inlined,
                after: "removed line",
                description: "removed line"
            )

            return mutated(node, with: newFunctionBody)
        }

        private func currentLineIsPositionToMutate(_ currentStatement: CodeBlockItemSyntax) -> Bool {
            return currentStatement.endPosition == positionToMutate
        }

        private func mutated(_ node: FunctionDeclSyntax, with body: CodeBlockSyntax) -> DeclSyntax {
            let functionDecl = SyntaxFactory.makeFunctionDecl(
                attributes: node.attributes,
                modifiers: node.modifiers,
                funcKeyword: node.funcKeyword,
                identifier: node.identifier,
                genericParameterClause: node.genericParameterClause,
                signature: node.signature,
                genericWhereClause: node.genericWhereClause,
                body: body
            )

            return DeclSyntax(functionDecl)
        }
    }
}
