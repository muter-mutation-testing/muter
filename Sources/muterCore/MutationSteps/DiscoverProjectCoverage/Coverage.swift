import Foundation

final class Coverage {
    let percent: Int
    let filesWithoutCoverage: [FilePath]
    let functionsCoverage: FunctionsCoverage
    /// The index store that the coverage build wrote, or `nil` when the build system has none.
    /// The folder can be missing, for example when the project sets its own build location.
    let indexStorePath: String?

    init(
        percent: Int = 0,
        filesWithoutCoverage: [FilePath] = [],
        functionsCoverage: FunctionsCoverage = .null,
        indexStorePath: String? = nil
    ) {
        self.percent = percent
        self.filesWithoutCoverage = filesWithoutCoverage
        self.functionsCoverage = functionsCoverage
        self.indexStorePath = indexStorePath
    }

    func regionsForFile(_ filePath: FilePath) -> [Region] {
        functionsCoverage.regionsForFile(filePath)
    }
}

extension Coverage: Equatable {
    static func == (lhs: Coverage, rhs: Coverage) -> Bool {
        (
            lhs.percent == rhs.percent
                && lhs.filesWithoutCoverage == rhs.filesWithoutCoverage
                && lhs.functionsCoverage == rhs.functionsCoverage
                && lhs.indexStorePath == rhs.indexStorePath
        )
            || lhs === rhs
    }
}

extension Coverage: Nullable {
    static var null: Coverage {
        Coverage(
            percent: -1,
            filesWithoutCoverage: [],
            functionsCoverage: .null
        )
    }
}
