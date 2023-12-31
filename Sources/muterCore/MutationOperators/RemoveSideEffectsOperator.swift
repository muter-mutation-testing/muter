import Foundation
import SwiftSyntax

enum RemoveSideEffectsOperator {
    final class Visitor: MuterVisitor {
        private var concurrencyPropertiesInFile = [String]()
        private let concurrencyTypes = [
            "DispatchSemaphore",
            "NSRecursiveLock",
            "NSCondition",
            "NSConditionLock",
        ]

        private lazy var untestedFunctionNames: [String] = [
            "print",
            "fatalError",
            "exit",
            "abort"
        ] + (configuration?.excludeCallList ?? [])

        convenience init(
            configuration: MuterConfiguration? = nil,
            sourceCodeInfo: SourceCodeInfo
        ) {
            self.init(
                configuration: configuration,
                sourceCodeInfo: sourceCodeInfo,
                mutationOperatorId: .removeSideEffects
            )
        }

        override func visit(_ node: PatternBindingListSyntax) -> SyntaxVisitorContinueKind {
            for statement in node where statementsContainsConcurrencyTypes(statement) {
                let property = propertyName(from: statement)
                concurrencyPropertiesInFile.append(property)
            }

            return super.visit(node)
        }

        override func visit(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind {
            removeSideEffectAt(node.body)

            return super.visit(node)
        }

        override func visit(_ node: GuardStmtSyntax) -> SyntaxVisitorContinueKind {
            removeSideEffectAt(node.body)

            return super.visit(node)
        }

        override func visit(_ node: WhileStmtSyntax) -> SyntaxVisitorContinueKind {
            removeSideEffectAt(node.body)

            return super.visit(node)
        }

        override func visit(_ node: RepeatStmtSyntax) -> SyntaxVisitorContinueKind {
            removeSideEffectAt(node.body)

            return super.visit(node)
        }

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            guard let body = node.body else {
                return super.visit(node)
            }

            guard !node.hasImplicitReturn else {
                return super.visit(node)
            }

            removeSideEffectAt(body)

            return super.visit(node)
        }

        private func removeSideEffectAt(_ body: CodeBlockSyntax) {
            let statements = body.statements
            for statement in body.statements where statementContainsMutableToken(statement) {
                let mutatedFunctionStatements = body
                    .statements
                    .exclude { $0.description == statement.description }

                let newCodeBlockItemList = CodeBlockItemListSyntax(mutatedFunctionStatements)

                let position = endLocation(for: statement)
                let snapshot = MutationOperator.Snapshot(
                    before: statement.description.trimmed.inlined,
                    after: "removed line",
                    description: "removed line"
                )

                checkNodeForDisableTag(statement)

                add(
                    mutation: newCodeBlockItemList,
                    with: statements,
                    at: position,
                    snapshot: snapshot
                )
            }
        }

        private func mutated(_ node: FunctionDeclSyntax, with body: CodeBlockSyntax) -> DeclSyntax {
            let functionDecl = FunctionDeclSyntax(
                attributes: node.attributes,
                modifiers: node.modifiers,
                funcKeyword: node.funcKeyword,
                name: node.name,
                genericParameterClause: node.genericParameterClause,
                signature: node.signature,
                genericWhereClause: node.genericWhereClause,
                body: body
            )

            return DeclSyntax(functionDecl)
        }

        private func statementContainsMutableToken(_ statement: CodeBlockItemListSyntax.Element) -> Bool {
            let doesntContainVariableAssignment = statement.allChildren.count(variableAssignmentStatements) == 0
            let containsDiscardedResult = statement.description.contains("_ = ")

            let containsFunctionCall = statement.allChildren
                .include(functionCallStatements)
                .exclude(untestedFunctionCallStatements)
                .count >= 1

            let doesntContainPossibleDeadlock = !statement.allChildren
                .exclude(concurrencyStatements)
                .isEmpty

            return doesntContainVariableAssignment
                && doesntContainPossibleDeadlock
                && (containsDiscardedResult || containsFunctionCall)
        }

        private func variableAssignmentStatements(_ node: Syntax) -> Bool {
            node.is(VariableDeclSyntax.self)
        }

        private func functionCallStatements(_ node: Syntax) -> Bool {
            node.is(FunctionCallExprSyntax.self)
        }

        private func concurrencyStatements(_ node: Syntax) -> Bool {
            guard let functionCallSyntax = node.as(FunctionCallExprSyntax.self),
                  let calledExpression = functionCallSyntax.calledExpression.as(MemberAccessExprSyntax.self),
                  let variableName = calledExpression.base?.description.trimmed
            else {
                return false
            }

            return concurrencyPropertiesInFile.contains(variableName)
        }

        private func untestedFunctionCallStatements(_ node: Syntax) -> Bool {
            untestedFunctionNames.contains { name in node.description.contains(name) }
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
