import SwiftSyntax

public extension SourceFileSyntax {
    static func makeBlankSourceFile() -> Self {
        SourceFileSyntax(
            statements: CodeBlockItemListSyntax([]),
            endOfFileToken: .endOfFileToken()
        )
    }
}
