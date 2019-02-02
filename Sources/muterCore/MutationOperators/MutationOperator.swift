import SwiftSyntax

typealias SourceCodeTransformation = (Syntax) -> Syntax
typealias MutationIdVisitorPair = (id: MutationOperator.Id, visitor: VisitorInitializer)
typealias RewriterInitializer = (AbsolutePosition) -> PositionSpecificRewriter
typealias VisitorInitializer = () -> PositionDiscoveringVisitor

struct MutationOperator {

    enum Id: String, Codable {
        case negateConditionals = "Negate Conditionals"
        case sideEffects = "Side Effects"

        static let rewriterPairs: [Id: RewriterInitializer] = [
            .sideEffects: RemoveSideEffectsOperator.Rewriter.init,
            .negateConditionals: NegateConditionalsOperator.Rewriter.init
        ]

        func transformation(for position: AbsolutePosition) -> SourceCodeTransformation {
            return { source in
                let visitor = Id.rewriterPairs[self]!(position)
                return visitor.visit(source)
            }
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

protocol PositionSpecificRewriter {
    var positionToMutate: AbsolutePosition { get }
    init(positionToMutate: AbsolutePosition)
    func visit(_ token: Syntax) -> Syntax
}

protocol PositionDiscoveringVisitor {
    var positionsOfToken: [AbsolutePosition] { get }
    func visit(_ token: SourceFileSyntax)
}
