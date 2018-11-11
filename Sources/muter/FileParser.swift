import SwiftSyntax
import Foundation

class FileParser {
    func load(path: String) throws -> SourceFileSyntax {
        let url = URL(fileURLWithPath: path)
        return try SyntaxTreeParser.parse(url)
    }
}
