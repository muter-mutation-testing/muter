@testable import muterCore

final class SourceCodePreparationSub {
    var sourceCodeToReturn: ((String) -> PreparedSourceCode?)?

    func prepare(_ file: String) -> PreparedSourceCode? {
        sourceCodeToReturn?(file)
    }
}
