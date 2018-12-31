import SwiftSyntax
import Foundation

func discoverMutationOperators(inFilesAt filePaths: [String]) -> [MutationOperator] {
	return filePaths.accumulate(into: []) { alreadyDiscoveredOperators, path in
		
		guard pathContainsDotSwift(path),
			let source = sourceCode(fromFileAt: path) else {
			return alreadyDiscoveredOperators
		}

		return alreadyDiscoveredOperators + newlyDiscoveredOperators(inFileAt: path, containing: source).sorted(by: filePositionOrder)
	}
}

private let idVisitorPairs: [MutationIdVisitorPair] = [
	(id: .sideEffects, visitor: SideEffectsMutation.Visitor.init),
	(id: .negateConditionals, visitor: NegateConditionalsMutation.Visitor.init)
]

private func newlyDiscoveredOperators(inFileAt path: String, containing source: SourceFileSyntax) -> [MutationOperator] {
	return idVisitorPairs.accumulate(into: []) { newOperators, values in
		
		let id = values.id
		let visitor = values.visitor()
		visitor.visit(source)
		
		return newOperators + visitor.positionsOfToken.map { position in
			
			return MutationOperator(id: id,
									filePath: path,
									position: position,
									source: source,
									transformation: id.transformation(for: position))
			
		}
	}
}

private func filePositionOrder(lhs: MutationOperator, rhs: MutationOperator) -> Bool {
	return lhs.position.line < rhs.position.line && lhs.position.column < rhs.position.column
}

private func pathContainsDotSwift(_ filePath: String) -> Bool {
	guard let url = URL(string: filePath) else { return false }
	return url.lastPathComponent.contains(".swift")
}
