import ArgumentParser
import Foundation
import Rainbow

public struct Operator: AsyncParsableCommand {

    public static let configuration = CommandConfiguration(
        commandName: "operator",
        abstract: "Describes a given mutation operator."
    )
    
    @Argument(
        help: """
            Avaiable operators are: \(MutationOperator.Id.description)
            For all operators use: \("all".italic)
        """
    )
    var `operator`: String
    
    public init() {}
    
    public mutating func run() async throws {
        if `operator`.trimmed == "all" {
            return print(MutationOperator.Id.allCases.map(\.documentation).joined(separator: "\n\n"))
        }

        guard let mutationOperator = MutationOperator.Id(rawValue: `operator`) else {
            throw MuterError.literal(reason: MutationOperator.Id.description)
        }
        
        print(mutationOperator.documentation)
    }
}

private extension MutationOperator.Id {
    var documentation: String {
        switch self {
        case .logicalOperator:
            return """
                
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
                """
                \("func".asKeyword) \("isValidPassword".asDeclaration)(\("_".asDeclaration) text: \("String".asTypeDeclaration), \("_".asDeclaration) repeatedText: \("String".asTypeDeclaration) \("->".asKeyword) \("Bool".asTypeDeclaration) {
                    \("let".asKeyword) meetsMinimumLength \("=".asKeyword) text.\("count".asTypeDeclaration) \(">=".asKeyword) \("8".asTypeDeclaration)
                    \("let".asKeyword) passwordsMatch \("=".asKeyword) repeatedText \("==".asKeyword) text
                    \("return".asKeyword) meetsMinimumLength \("&&".asKeyword) passwordsMatch
                }
                """
                .onCodeBlock
                )
                
                becomes

                \(
                """
                \("func".asKeyword) \("isValidPassword".asDeclaration)(\("_".asDeclaration) text: \("String".asTypeDeclaration), \("_".asDeclaration) repeatedText: \("String".asTypeDeclaration) \("->".asKeyword) \("Bool".asTypeDeclaration) {
                    \("let".asKeyword) meetsMinimumLength \("=".asKeyword) text.\("count".asTypeDeclaration) \(">=".asKeyword) \("8".asTypeDeclaration)
                    \("let".asKeyword) passwordsMatch \("=".asKeyword) repeatedText \("==".asKeyword) text
                    \("return".asKeyword) meetsMinimumLength \("||".asKeyword) passwordsMatch
                }
                """
                .onCodeBlock
                )
                
                """
        case .removeSideEffects:
            return """
                
                \("Remove Side Effects".bold)
                
                The \("remove side effects".italic) operator will remove code it determines is causing a side effect.
                It will determine your code is causing a side effect based on a few rules:
                    • A line contains a function call which is explicitly discarding a return result.
                    • A line contains a function call and doesn't save the result of the function call into a named variable or constant (i.e. a line implicitly discards a return result or doesn't produce one).
                    • A line does not contain a call to \("print".onCodeEscape), \("exit".onCodeEscape), \("fatalError".onCodeEscape),\("abort".onCodeEscape), or any function listed in \("muter.conf.yml".onCodeEscape) under the \("excludeCalls".onCodeEscape) key.
                The purpose of this operator is to highlight how your tests respond to the absence of expected side effects.

                \("Mutating an explicitly discarded return result".bold)
                
                \("""
                \("func".asKeyword) initialize() {
                    \("_".asTypeDeclaration) \("=".asKeyword) \("self".asTypeDeclaration).view
                    view.results \("=".asKeyword) \("self".asTypeDeclaration).results
                }
                """.onCodeBlock
                )
                
                becomes

                \("""
                \("func".asKeyword) initialize() {
                    view.results \("=".asKeyword) \("self".asTypeDeclaration).results
                }
                """.onCodeBlock
                )
                
                \("Mutating a void function call".bold)
                
                \("""
                \("func".asKeyword) \("update".asDeclaration)(\("email".asDeclaration): \("String".asTypeDeclaration), \("for".asDeclaration) userId: \("String".asTypeDeclaration) {
                    \("var".asKeyword) userRecord = \("record".asTypeDeclaration)(\("for".asTypeDeclaration): userId)
                    userRecord.email \("=".asKeyword) email
                    database.\("persist".asTypeDeclaration)(userRecord)
                }
                """.onCodeBlock
                )
                
                becomes

                \("""
                \("func".asKeyword) \("update".asDeclaration)(\("email".asDeclaration): \("String".asTypeDeclaration), \("for".asDeclaration) userId: \("String".asTypeDeclaration) {
                    \("var".asKeyword) userRecord = \("record".asTypeDeclaration)(\("for".asTypeDeclaration): userId)
                    userRecord.email \("=".asKeyword) email
                }
                """.onCodeBlock
                )
                """
        case .ror:
            return """
                
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
                
                \("""
                \("if".asKeyword) myValue == \("50".asTypeDeclaration) {
                    \("// something happens here".asComment)
                }
                """.onCodeBlock
                )
                
                becomes

                \("""
                \("if".asKeyword) myValue != \("50".asTypeDeclaration) {
                    \("// something happens here".asComment)
                }
                """.onCodeBlock
                )
                """
        case .swapTernary:
            return """
                
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
                
                \("""
                \("func".asKeyword) \("stringify".asDeclaration)(\("_".asDeclaration) a: \("Bool".asTypeDeclaration) \("->".asKeyword) \("String".asTypeDeclaration) {
                    \("return".asKeyword) a \("?".asKeyword) \("\"true\"".asTypeDeclaration) : \("\"false\"".asTypeDeclaration)
                }
                """.onCodeBlock
                )
                
                becomes
                
                \("""
                \("func".asKeyword) \("stringify".asDeclaration)(\("_".asKeyword) a: \("Bool".asTypeDeclaration) \("->".asKeyword) \("String".asTypeDeclaration) {
                    \("return".asKeyword) a \("?".asKeyword) \("\"false\"".asTypeDeclaration) : \("\"true\"".asTypeDeclaration)
                }
                """.onCodeBlock
                )
                
                """
        }
    }
}

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
