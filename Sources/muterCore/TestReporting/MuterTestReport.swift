import Foundation
import SwiftSyntax

typealias FileName = String
typealias FilePath = String

public func xcodeReporter(report: MuterTestReport) -> String {
    // {full_path_to_file}{:line}{:character}: {error,warning}: {content}
    return report.fileReports.map { (file: MuterTestReport.FileReport) -> String in
        let path = file.path
        return file.appliedOperators
            .filter { $0.testSuiteOutcome == .passed }
            .map {
                "\(path):" +
                    "\($0.position.line):\($0.position.column): " +
                    "warning: " +
                "\"Your test suite did not kill this mutant: \($0.id.rawValue.lowercased())\""
            }.joined(separator: "\n")
        }.joined(separator: "\n")
}

public struct MuterTestReport {
    let globalMutationScore: Int
    let totalAppliedMutationOperators: Int
    let numberOfKilledMutants: Int
    let fileReports: [FileReport]

    public init(from outcomes: [MutationTestOutcome] = []) {
        globalMutationScore = mutationScore(from: outcomes.map { $0.testSuiteOutcome })
        totalAppliedMutationOperators = outcomes.count
        numberOfKilledMutants = outcomes.map{ $0.testSuiteOutcome }.count { $0 == .failed || $0 == .runtimeError }
        fileReports = MuterTestReport.fileReports(from: outcomes)
    }
}

extension MuterTestReport {
    struct FileReport: Codable, Equatable {
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

    struct AppliedMutationOperator: Codable, Equatable {
        let id: MutationOperator.Id
        let position: AbsolutePosition
        let testSuiteOutcome: TestSuiteOutcome
    }
}

private extension MuterTestReport {
    static func fileReports(from outcomes: [MutationTestOutcome]) -> [FileReport] {
        return mutationScoreOfFiles(from: outcomes)
            .sorted(by: ascendingFilenameOrder)
            .map { mutationScoreByFilePath in
                let filePath = mutationScoreByFilePath.key
                let fileName = URL(fileURLWithPath: filePath).lastPathComponent
                let mutationScore = mutationScoreByFilePath.value
                let appliedMutations = outcomes
                    .include { $0.filePath == mutationScoreByFilePath.key }
                    .map{ AppliedMutationOperator(id: $0.appliedMutation, position: $0.position, testSuiteOutcome: $0.testSuiteOutcome) }

                return (fileName, filePath, mutationScore, appliedMutations)
            }
            .map(FileReport.init(fileName:path:mutationScore:appliedOperators:))
    }
}

private func ascendingFilenameOrder(lhs: (key: String, value: Int), rhs: (key: String, value: Int)) -> Bool {
    return lhs.key < rhs.key
}

extension MuterTestReport: Equatable {}
extension MuterTestReport: Codable {}
