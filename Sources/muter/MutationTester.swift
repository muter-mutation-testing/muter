import SwiftSyntax
import Foundation

class MutationTester {
    enum ParsingError: Error {
        case fileNotFound
    }
    
    func load(path: String) throws -> SourceFileSyntax {
        let url = URL(fileURLWithPath: path)
        return try SyntaxTreeParser.parse(url)
    }
}
