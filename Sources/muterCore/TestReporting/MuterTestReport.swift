import Foundation

typealias FileName = String
public typealias FilePath = String

struct MuterTestReport {
    let globalMutationScore: Int
    let totalAppliedMutationOperators: Int
    let numberOfKilledMutants: Int
    let projectCodeCoverage: Int?
    let fileReports: [FileReport]
    let timeElapsed: String

    init(
        from outcome: MutationTestOutcome = .init()
    ) {
        globalMutationScore = mutationScore(from: outcome.mutations.map { $0.testSuiteOutcome })
        totalAppliedMutationOperators = outcome.mutations.count
        numberOfKilledMutants = outcome.mutations
            .count { $0.testSuiteOutcome == .failed || $0.testSuiteOutcome == .runtimeError }
        projectCodeCoverage = outcome.coverage == .null ? nil : outcome.coverage.percent
        fileReports = MuterTestReport.fileReports(from: outcome)
        timeElapsed = outcome.testDuration.formatted()
    }
}

private extension TimeInterval{
    func formatted() -> String {
        let time = NSInteger(self)
        let ms = Int(truncatingRemainder(dividingBy: 1) * 1000)
        let seconds = time % 60
        let minutes = (time / 60) % 60
        let hours = (time / 3600)
        
        return String(
            format: "%0.2d:%0.2d:%0.2d.%0.3d",
            hours,
            minutes,
            seconds,
            ms
        )
        
    }
}

extension MuterTestReport {
    struct FileReport: Codable {
        let fileName: FileName
        let path: FilePath
        let mutationScore: Int
        let appliedOperators: [AppliedMutationOperator]

        enum CodingKeys: String, CodingKey {
            case fileName
            case mutationScore
            case appliedOperators
        }

        init(fileName: FileName, path: FilePath, mutationScore: Int, appliedOperators: [AppliedMutationOperator]) {
            self.fileName = fileName
            self.path = path
            self.mutationScore = mutationScore
            self.appliedOperators = appliedOperators
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            fileName = try container.decode(FileName.self, forKey: .fileName)
            mutationScore = try container.decode(Int.self, forKey: .mutationScore)
            appliedOperators = try container.decode([AppliedMutationOperator].self, forKey: .appliedOperators)
            path = ""
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(fileName, forKey: .fileName)
            try container.encode(mutationScore, forKey: .mutationScore)
            try container.encode(appliedOperators, forKey: .appliedOperators)
        }
    }
}

extension MuterTestReport.FileReport: Comparable {
    static func < (lhs: MuterTestReport.FileReport, rhs: MuterTestReport.FileReport) -> Bool {
        lhs.fileName.localizedStandardCompare(rhs.fileName) == .orderedAscending
    }
}

extension MuterTestReport {
    struct AppliedMutationOperator: Codable, Equatable {
        let mutationPoint: MutationPoint
        let mutationSnapshot: MutationOperatorSnapshot
        let testSuiteOutcome: TestSuiteOutcome

        enum CodingKeys: String, CodingKey {
            case mutationPoint
            case testSuiteOutcome
        }

        init(
            mutationPoint: MutationPoint,
            mutationSnapshot: MutationOperatorSnapshot,
            testSuiteOutcome: TestSuiteOutcome
        ) {
            self.mutationPoint = mutationPoint
            self.mutationSnapshot = mutationSnapshot
            self.testSuiteOutcome = testSuiteOutcome
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            mutationPoint = try container.decode(MutationPoint.self, forKey: .mutationPoint)
            testSuiteOutcome = try container.decode(TestSuiteOutcome.self, forKey: .testSuiteOutcome)
            mutationSnapshot = .null
        }
    }
}

private extension MuterTestReport {
    static func fileReports(from outcome: MutationTestOutcome) -> [FileReport] {
        let outcomes = outcome.mutations
        let filesWithoutCoverage = outcome.coverage.filesWithoutCoverage

        let scoreOfFiles = mutationScoresOfFiles(from: outcomes)
            .sorted(by: ascendingFilenameOrder)
            .map { mutationScoreByFilePath in
                let filePath = mutationScoreByFilePath.key
                let fileName = URL(fileURLWithPath: filePath).lastPathComponent
                let mutationScore = mutationScoreByFilePath.value
                let appliedOperators = outcomes
                    .include { $0.point.filePath == mutationScoreByFilePath.key }
                    .map { AppliedMutationOperator(
                        mutationPoint: $0.point,
                        mutationSnapshot: $0.snapshot,
                        testSuiteOutcome: $0.testSuiteOutcome)
                    }

                return (fileName, filePath, mutationScore, appliedOperators)
            }
            .map(FileReport.init(fileName:path:mutationScore:appliedOperators:))
        
        let scoreOfFilesWithoutCoverage = filesWithoutCoverage.map { filePath in
            FileReport(
                fileName: URL(fileURLWithPath: filePath).lastPathComponent,
                path: filePath,
                mutationScore: 0,
                appliedOperators: [
                    .init(
                        mutationPoint: .null,
                        mutationSnapshot: .null,
                        testSuiteOutcome: .noCoverage
                    ),
                ]
            )
        }
        
        return scoreOfFiles + scoreOfFilesWithoutCoverage
    }
}

private func ascendingFilenameOrder(
    lhs: (key: String, value: Int),
    rhs: (key: String, value: Int)
) -> Bool {
    return lhs.key < rhs.key
}

extension MuterTestReport: Equatable {}
extension MuterTestReport: Codable {}
