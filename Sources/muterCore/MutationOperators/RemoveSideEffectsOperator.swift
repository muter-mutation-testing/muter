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
            "preconditionFailure",
            "exit",
            "abort",
        ] + (configuration?.excludeCallList ?? [])

        convenience init(
            configuration: MuterConfiguration? = nil,
            sourceCodeInfo: SourceCodeInfo,
            regionsWithoutCoverage: [Region] = []
        ) {
            self.init(
                configuration: configuration,
                sourceCodeInfo: sourceCodeInfo,
                mutationOperatorId: .removeSideEffects,
                regionsWithoutCoverage: regionsWithoutCoverage
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

        override func visit(_ node: DoStmtSyntax) -> SyntaxVisitorContinueKind {
            removeSideEffectAt(node.body)

            return super.visit(node)
        }

        /// Statements inside a closure, for example the body passed to `forEach`. Two rules keep the
        /// mutants compiling, as for function bodies:
        /// - A closure with one statement can return that statement's value implicitly, so removing it
        ///   would change the closure's type. Only closures with more than one statement are mutated.
        /// - A closure that contains `guard`, `for`, `while`, `repeat` or `do` is skipped, because a
        ///   `guard let` declares names that later statements use. Those statements' own bodies are
        ///   mutated instead.
        override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
            guard node.statements.count > 1,
                  !containsNodesThatWillBeVisited(node.statements)
            else {
                return super.visit(node)
            }

            removeSideEffectAt(node.statements)

            return super.visit(node)
        }

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            guard let body = node.body,
                  !node.hasImplicitReturn,
                  !containsNodesThatWillBeVisited(body)
            else {
                return super.visit(node)
            }

            removeSideEffectAt(body)

            return super.visit(node)
        }

        private func removeSideEffectAt(_ body: CodeBlockSyntax) {
            removeSideEffectAt(body.statements)
        }

        private func removeSideEffectAt(_ statements: CodeBlockItemListSyntax) {
            for statement in statements where statementContainsMutableToken(statement) {
                let mutatedFunctionStatements = statements
                    .exclude { $0.description == statement.description }

                let newCodeBlockItemList = CodeBlockItemListSyntax(mutatedFunctionStatements)

                let position = endLocation(for: statement)
                let snapshot = MutationOperator.Snapshot(
                    before: statement.description.trimmed.inlined,
                    after: "removed line",
                    description: "removed line"
                )

                add(
                    mutation: newCodeBlockItemList,
                    with: statements,
                    at: position,
                    snapshot: snapshot,
                    startLine: startLocation(for: statement).line,
                    mutatedNode: statement,
                    replacement: ""
                )
            }
        }

        private func statementContainsMutableToken(_ statement: CodeBlockItemListSyntax.Element) -> Bool {
            let doesntContainVariableAssignment = doesntContainVariableAssignment(statement.allChildren)
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

        private func doesntContainVariableAssignment(_ children: SyntaxChildren) -> Bool {
            let childrenAssignment = children.count(variableAssignmentStatements) == 0
            let doStatementAssignment = filterDoStatement(children).count(variableAssignmentStatements) == 0

            return childrenAssignment || doStatementAssignment
        }

        private func filterDoStatement(_ children: SyntaxChildren) -> [Syntax] {
            children
                .compactMap { $0.as(DoStmtSyntax.self) }
                .map(\.body)
                .compactMap(Syntax.init)
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

        // This is to avoid false positives for code block items such as do statement
        // We are going to visit them individually
        private func containsNodesThatWillBeVisited(_ node: CodeBlockSyntax) -> Bool {
            containsNodesThatWillBeVisited(node.statements)
        }

        private func containsNodesThatWillBeVisited(_ statements: CodeBlockItemListSyntax) -> Bool {
            let skippableNodes: [SyntaxProtocol.Type] = [
                ForStmtSyntax.self,
                GuardStmtSyntax.self,
                WhileStmtSyntax.self,
                RepeatStmtSyntax.self,
                DoStmtSyntax.self,
            ]
            let syntaxNodes = statements.map(\.item._syntaxNode)
            for item in syntaxNodes {
                for s in skippableNodes {
                    if item.is(s) {
                        return true
                    }
                }
            }

            return false
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
