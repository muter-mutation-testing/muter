// swiftformat:disable all

import ArgumentParser
import Foundation
import Rainbow
import SyntaxHighlighter

public struct Operator: ParsableCommand {

    public static let configuration = CommandConfiguration(
        commandName: "operator",
        abstract: "Describes a given mutation operator."
    )
    
    @Argument(help: "Avaiable operators are: all, \(MutationOperator.Id.description)")
    var `operator`: String
        
    public init() {}
    
    public func run() throws {
        if `operator`.trimmed == "all" {
            print(MutationOperator.Id.allCases.map(\.documentation).joined())
            return
        }
        
        guard let mutationOperator = MutationOperator.Id(rawValue: `operator`) else {
            throw MuterError.literal(reason: MutationOperator.Id.description)
        }
        
        print(mutationOperator.documentation)
    }
}

extension MutationOperator.Id {
    var documentation: String {
        switch self {
        case .logicalOperator:
            return
                """
                
                \("Change Logical Connector".bold)
                
                The \("change logical connector".italic) operator will change conditional operators in your code based on this table:
                
                +-------------------+------------------+
                | Original Operator | Changed Operator |
                +-------------------+------------------+
                |        \(" && ".onCodeEscape)       |       \(" || ".onCodeEscape)       |
                \("""
                +-------------------+------------------+
                |        \(" || ".onCodeEscape)       |       \(" && ".onCodeEscape)       |
                +-------------------+------------------+
                """.onCodeBlock
                )

                The purpose of this operator is to highlight how your tests respond to changes in logic.
                A well-engineered test suite will be able to fail clearly in response to different logical constraints.

                \("Mutating a Logical".bold) \("AND".bold.italic)
                
                \(
                    highlightCode(
                        """
                        func isValidPassword(_ text: String, _ repeatedText: String) -> Bool {
                            let meetsMinimumLength = text.count >= 8
                            let passwordsMatch = repeatedText == text
                            return meetsMinimumLength && passwordsMatch
                        }
                        """
                    ).onCodeBlock
                )
                
                becomes

                \(
                    highlightCode(
                        """
                        func isValidPassword(_ text: String, _ repeatedText: String) -> Bool {
                            let meetsMinimumLength = text.count >= 8
                            let passwordsMatch = repeatedText == text
                            return meetsMinimumLength || passwordsMatch
                        }
                        """
                    ).onCodeBlock
                )
                
                """
        case .removeSideEffects:
            return
                """
                
                \("Remove Side Effects".bold)
                
                The \("remove side effects".italic) operator will remove code it determines is causing a side effect.
                It will determine your code is causing a side effect based on a few rules:
                    • A line contains a function call which is explicitly discarding a return result.
                    • A line contains a function call and doesn't save the result of the function call into a named variable or constant (i.e. a line implicitly discards a return result or doesn't produce one).
                    • A line does not contain a call to \("print".onCodeEscape), \("exit".onCodeEscape), \("fatalError".onCodeEscape),\("abort".onCodeEscape), or any function listed in \("muter.conf.yml".onCodeEscape) under the \("excludeCalls".onCodeEscape) key.
                The purpose of this operator is to highlight how your tests respond to the absence of expected side effects.

                \("Mutating an explicitly discarded return result".bold)
                
                \(
                    highlightCode(
                        """
                        func initialize() {
                            _ = self.view
                            view.results = self.results
                        }
                        """
                    ).onCodeBlock
                )
                
                becomes

                \(
                    highlightCode(
                        """
                        func initialize() {
                            view.results = self.results
                        }
                        """
                    ).onCodeBlock
                )
                
                \("Mutating a void function call".bold)
                
                \(
                    highlightCode(
                        """
                        func update(email: String, for userId: String) {
                            var userRecord = record(for: userId)
                            userRecord.email = email
                            database.persist(userRecord)
                        }
                        """
                    ).onCodeBlock
                )
                
                becomes

                \(
                    highlightCode(
                        """
                        func update(email: String, for userId: String) {
                            var userRecord = record(for: userId)
                            userRecord.email = email
                        }
                        """
                    ).onCodeBlock
                )
                """
        case .ror:
            return
                """
                
                \("Relational Operator Replacement".bold)
                
                The \("relational operator replacement".italic) operator will invert conditional operators in your code based on this table:

                +-------------------+------------------+
                | Original Operator | Changed Operator |
                +-------------------+------------------+
                |       \(" == ".onCodeEscape)        |       \(" != ".onCodeEscape)      |
                \("""
                +-------------------+-----------------+
                |       \(" != ".onCodeEscape)        |       \(" == ".onCodeEscape)      |
                +-------------------+-----------------+
                """.onCodeBlock
                )
                |       \(" >= ".onCodeEscape)        |       \(" <= ".onCodeEscape)      |
                \("""
                +-------------------+-----------------+
                |       \(" <= ".onCodeEscape)        |       \(" >= ".onCodeEscape)      |
                +-------------------+-----------------+
                """.onCodeBlock
                )
                |       \(" > ".onCodeEscape)         |       \(" < ".onCodeEscape)       |
                \("""
                +-------------------+-----------------+
                |       \(" < ".onCodeEscape)         |       \(" > ".onCodeEscape)       |
                +-------------------+-----------------+
                """.onCodeBlock
                )
                
                
                The purpose of this operator is to highlight how your tests respond to changes in branching logic.
                A well-engineered test suite will be able to fail clearly in response to code taking a different branch than it expected.
                
                \("Mutating an equality check".bold)
                
                \(
                    highlightCode(
                        """
                        if myValue == 50 {
                            // something happens here
                        }
                        """
                    ).onCodeBlock
                )
                
                becomes
                
                \(
                    highlightCode(
                        """
                        if myValue != 50 {
                            // something happens here
                        }
                        """
                    ).onCodeBlock
                )
                """
        case .swapTernary:
            return
                """
                
                \("Swap Ternary".bold)
                
                The \("swap ternary".italic) operator will swap ternary operators in your code based on this table:

                +---------------------------------------------+---------------------------------------------+
                |              Original Operator              |               Changed Operator              |
                +---------------------------------------------+---------------------------------------------+
                |\(" <condition> ? <expression1> : <expression2> ".onCodeEscape)|\(" <condition> ? <expression2> : <expression1> ".onCodeEscape)|
                +---------------------------------------------+---------------------------------------------+
                
                The purpose of this operator is to highlight how your tests respond to changes in logic.
                A well-engineered test suite will be able to fail clearly in response to different logical constraints.
                
                \("Mutation a ternary expression".bold)
                
                \(
                    highlightCode(
                        """
                        func stringify(_ a: Bool) -> String {
                            return a ? "true" : "false"
                        }
                        """
                    ).onCodeBlock
                )
                
                becomes
                
                \(
                    highlightCode(
                        """
                        func stringify(_ a: Bool) -> String {
                            return a ? "false" : "true"
                        }
                        """
                    ).onCodeBlock
                )
                
                """
        }
    }
}

private func highlightCode(_ code: String) -> String {
    Visitor.highlightCode(code, theme: highlightTheme)
}

let highlightTheme = Theme(
    transformer: [
        [.classKeyword,
         .deinitKeyword,
         .associatedtypeKeyword,
         .extensionKeyword,
         .enumKeyword,
         .funcKeyword,
         .importKeyword,
         .initKeyword,
         .inoutKeyword,
         .letKeyword,
         .operatorKeyword,
         .precedencegroupKeyword,
         .protocolKeyword,
         .structKeyword,
         .returnKeyword,
         .asKeyword,
         .varKeyword,
         .fileprivateKeyword,
         .internalKeyword,
         .privateKeyword,
         .publicKeyword,
         .staticKeyword,
         .deferKeyword,
         .ifKeyword,
         .guardKeyword,
         .doKeyword,
         .repeatKeyword,
         .elseKeyword,
         .forKeyword,
         .inKeyword,
         .whileKeyword,
         .breakKeyword,
         .continueKeyword,
         .fallthroughKeyword,
         .switchKeyword,
         .defaultKeyword,
         .whereKeyword,
         .catchKeyword,
         .throwKeyword,
         .anyKeyword,
         .falseKeyword,
         .isKeyword,
         .caseKeyword,
         .nilKeyword,
         .rethrowsKeyword,
         .typealiasKeyword,
         .selfKeyword,
         .superKeyword,
         .throwsKeyword,
         .capitalSelfKeyword,
         .prefixPeriod,
         .equal,
         .arrow
        ]: { $0.asKeyword },
        [
            .trueKeyword,
            .wildcardKeyword,
            .integerLiteral
        ]: { $0.asTypeDeclaration }
    ],
    commentsTransformer: { $0.asComment }
)

private extension String {
    var asKeyword: String {
        hex("#FF7B72")
    }
    
    var asDeclaration: String {
        hex("#D2A8FE")
    }
    
    var asTypeDeclaration: String {
        hex("#79C0FF")
    }
    
    var onCodeEscape: String {
        onHex("#343940")
    }
    
    var onCodeBlock: String {
        onHex("#161B22")
    }
    
    var asComment: String {
        hex("#50575F")
    }
}
