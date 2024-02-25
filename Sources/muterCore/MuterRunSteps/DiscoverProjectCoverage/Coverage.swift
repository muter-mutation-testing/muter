import Foundation

final class Coverage {
    let percent: Int
    let filesWithoutCoverage: [FilePath]
    let functionsCoverage: FunctionsCoverage

    init(
        percent: Int,
        filesWithoutCoverage: [FilePath],
        functionsCoverage: FunctionsCoverage
    ) {
        self.percent = percent
        self.filesWithoutCoverage = filesWithoutCoverage
        self.functionsCoverage = functionsCoverage
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
