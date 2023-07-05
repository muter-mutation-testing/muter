import Foundation
import SwiftSyntax

public struct Theme {
    let transformer: [[TokenKind]: (String) -> String]
    let commentsTransformer: (String) -> String
    
    public init(
        transformer: [[TokenKind] : (String) -> String],
        commentsTransformer: @escaping (String) -> String = { $0 }
    ) {
        self.transformer = transformer
        self.commentsTransformer = commentsTransformer
    }
}
