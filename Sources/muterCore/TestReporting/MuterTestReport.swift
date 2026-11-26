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
    /// Mutants, killed mutants and failed tests for each mutation operator.
    let operatorReports: [OperatorReport]
    /// The average number of failed tests per mutant, over the mutants whose test run reported a
    /// count (a surviving mutant counts as 0). `nil` when no run reported a count.
    let averageNumberOfFailedTests: Double?

    init(from outcome: MutationTestOutcome = .init()) {
        globalMutationScore = mutationScore(from: outcome.mutations.map { $0.testSuiteOutcome })
        totalAppliedMutationOperators = outcome.mutations.count
        numberOfKilledMutants = outcome.mutations
            .count { $0.testSuiteOutcome == .failed || $0.testSuiteOutcome == .runtimeError }
        projectCodeCoverage = outcome.coverage == .null ? nil : outcome.coverage.percent
        fileReports = MuterTestReport.fileReports(from: outcome)
        timeElapsed = outcome.testDuration.formatted()
        operatorReports = OperatorReport.reports(from: outcome.mutations)
        averageNumberOfFailedTests = average(outcome.mutations.compactMap(\.failedTests))
    }
}

extension MuterTestReport {
    struct OperatorReport: Codable, Equatable {
        let mutationOperator: MutationOperator.Id
        let numberOfMutants: Int
        let numberOfKilledMutants: Int
        /// The failed tests of all this operator's mutants whose test run reported a count.
        let numberOfFailedTests: Int
        let averageNumberOfFailedTests: Double?

        static func reports(from mutations: [MutationTestOutcome.Mutation]) -> [OperatorReport] {
            MutationOperator.Id.allCases.compactMap { id in
                let mutants = mutations.filter { $0.point.mutationOperatorId == id }
                guard !mutants.isEmpty else {
                    return nil
                }

                let counts = mutants.compactMap(\.failedTests)
                return OperatorReport(
                    mutationOperator: id,
                    numberOfMutants: mutants.count,
                    numberOfKilledMutants: mutants.count {
                        $0.testSuiteOutcome == .failed || $0.testSuiteOutcome == .runtimeError
                    },
                    numberOfFailedTests: counts.reduce(0, +),
                    averageNumberOfFailedTests: average(counts)
                )
            }
        }
    }
}

/// The average, rounded to two decimals, or `nil` for no values.
private func average(_ values: [Int]) -> Double? {
    guard !values.isEmpty else {
        return nil
    }

    let average = Double(values.reduce(0, +)) / Double(values.count)
    return (average * 100).rounded() / 100
}

private extension TimeInterval {
    func formatted() -> String {
        let time = Int(self)
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
        let mutationSnapshot: MutationOperator.Snapshot
        let testSuiteOutcome: TestSuiteOutcome
        /// How many tests failed with this mutant, when the test run reported it.
        let numberOfFailedTests: Int?

        enum CodingKeys: String, CodingKey {
            case mutationPoint
            case testSuiteOutcome
            case mutationSnapshot
            case numberOfFailedTests
        }

        init(
            mutationPoint: MutationPoint,
            mutationSnapshot: MutationOperator.Snapshot,
            testSuiteOutcome: TestSuiteOutcome,
            numberOfFailedTests: Int? = nil
        ) {
            self.mutationPoint = mutationPoint
            self.mutationSnapshot = mutationSnapshot
            self.testSuiteOutcome = testSuiteOutcome
            self.numberOfFailedTests = numberOfFailedTests
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            mutationPoint = try container.decode(MutationPoint.self, forKey: .mutationPoint)
            testSuiteOutcome = try container.decode(TestSuiteOutcome.self, forKey: .testSuiteOutcome)
            mutationSnapshot = container.decode(
                MutationOperator.Snapshot.self,
                default: .null,
                forKey: .mutationSnapshot
            )
            numberOfFailedTests = try container.decodeIfPresent(Int.self, forKey: .numberOfFailedTests)
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
                    .map {
                        AppliedMutationOperator(
                            mutationPoint: $0.point,
                            mutationSnapshot: $0.snapshot,
                            testSuiteOutcome: $0.testSuiteOutcome,
                            numberOfFailedTests: $0.failedTests
                        )
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
    lhs.key < rhs.key
}

extension MuterTestReport: Equatable {}
extension MuterTestReport: Codable {
    enum CodingKeys: String, CodingKey {
        case globalMutationScore
        case totalAppliedMutationOperators
        case numberOfKilledMutants
        case projectCodeCoverage
        case fileReports
        case timeElapsed
        case operatorReports
        case averageNumberOfFailedTests
    }

    /// Reports written before `operatorReports` and `averageNumberOfFailedTests` existed still decode.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        globalMutationScore = try container.decode(Int.self, forKey: .globalMutationScore)
        totalAppliedMutationOperators = try container.decode(Int.self, forKey: .totalAppliedMutationOperators)
        numberOfKilledMutants = try container.decode(Int.self, forKey: .numberOfKilledMutants)
        projectCodeCoverage = try container.decodeIfPresent(Int.self, forKey: .projectCodeCoverage)
        fileReports = try container.decode([FileReport].self, forKey: .fileReports)
        timeElapsed = try container.decode(String.self, forKey: .timeElapsed)
        operatorReports = try container.decodeIfPresent([OperatorReport].self, forKey: .operatorReports) ?? []
        averageNumberOfFailedTests = try container.decodeIfPresent(Double.self, forKey: .averageNumberOfFailedTests)
    }
}
