import SwiftSyntax

typealias SourceCodeTransformation = (Syntax) -> Syntax
typealias MutationIdVisitorPair = (id: MutationOperator.Id, visitor: VisitorInitializer)
typealias RewriterInitializer = (AbsolutePosition) -> PositionSpecificRewriter
typealias VisitorInitializer = () -> PositionDiscoveringVisitor

public struct MutationOperator: CustomStringConvertible {

    public var description: String {
        return id.description(for: source, at: position)
    }

    public enum Id: String, Codable {
        case negateConditionals = "Negate Conditionals"
        case removeSideEffects = "Remove Side Effects"

        static let rewriterPairs: [Id: RewriterInitializer] = [
            .removeSideEffects: RemoveSideEffectsOperator.Rewriter.init,
            .negateConditionals: NegateConditionalsOperator.Rewriter.init
        ]

        func transformation(for position: AbsolutePosition) -> SourceCodeTransformation {
            return { source in
                let visitor = Id.rewriterPairs[self]!(position)
                return visitor.visit(source)
            }
        }

        func description(for syntax: Syntax, at position: AbsolutePosition) -> String {
            let rewriter = Id.rewriterPairs[self]!(position)
            _ = rewriter.visit(syntax)
            return rewriter.description
        }
    }

    let id: Id
    let filePath: String
    let position: AbsolutePosition
    private let source: Syntax
    private let transformation: SourceCodeTransformation

    init(id: Id, filePath: String, position: AbsolutePosition, source: Syntax, transformation: @escaping SourceCodeTransformation) {
        self.id = id
        self.filePath = filePath
        self.position = position
        self.source = source
        self.transformation = transformation
    }

    func apply() -> Syntax {
        return transformation(source)
    }
}

protocol PositionSpecificRewriter: CustomStringConvertible {
    var positionToMutate: AbsolutePosition { get }
    init(positionToMutate: AbsolutePosition)
    func visit(_ token: Syntax) -> Syntax
}

protocol PositionDiscoveringVisitor {
    var positionsOfToken: [AbsolutePosition] { get }
    func visit(_ token: SourceFileSyntax)
}
