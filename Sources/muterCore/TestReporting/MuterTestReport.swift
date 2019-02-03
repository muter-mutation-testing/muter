import Foundation
import SwiftSyntax

typealias FileName = String

struct MuterTestReport: Encodable, Equatable {
    let globalMutationScore: Int
    let totalAppliedMutationOperators: Int
    let fileReports: [FileReport]
    
    init(from outcomes: [MutationTestOutcome]) {
        globalMutationScore = mutationScore(from: outcomes.map { $0.testSuiteResult })
        totalAppliedMutationOperators = outcomes.count
        fileReports = mutationScoreOfFiles(from: outcomes)
            .sorted(by: ascendingFilenameOrder)
            .map { mutationScoreByFilePath in
                let filePath = mutationScoreByFilePath.key
                let fileName = URL(fileURLWithPath: filePath).lastPathComponent
                let mutationScore = mutationScoreByFilePath.value
//                let appliedMutationsCount = outcomes.include { $0.filePath == mutationScoreByFilePath.key }.count
                //                (0 ..< appliedMutationsCount).map {
                //                    return AppliedMutationOperator()
                //                }
                return (fileName, mutationScore)
            }
            .map(FileReport.init)
    }
    
    struct FileReport: Encodable, Equatable {
        let fileName: FileName
        let mutationScore: Int
//        let appliedOperators: [AppliedMutationOperator]
    }
    
    struct AppliedMutationOperator: Encodable {
        let id: MutationOperator.Id
        let position: AbsolutePosition
        let testSuiteOutcome: TestSuiteOutcome
    }
}

extension MuterTestReport: CustomStringConvertible {
    var description: String {
        return "you didn't do this yet son!"
    }
}

// MARK - Mutation Score Calculation

func mutationScore(from testResults: [TestSuiteOutcome]) -> Int {
    guard testResults.count > 0 else {
        return -1
    }

    let numberOfFailures = Double(testResults.count { $0 == .failed || $0 == .runtimeError })
    let totalResults = Double(testResults.count { $0 != .buildError })
    return Int((numberOfFailures / totalResults) * 100.0)
}

func mutationScoreOfFiles(from outcomes: [MutationTestOutcome]) -> [String: Int] {
    var mutationScores: [String: Int] = [:]
    
    let filePaths = outcomes.map { $0.filePath }.deduplicated()
    for filePath in filePaths {
        let testSuiteResults = outcomes.include { $0.filePath == filePath }.map { $0.testSuiteResult }
        mutationScores[filePath] = mutationScore(from: testSuiteResults)
    }
    
    return mutationScores
}
//
//struct MuterTestReport2 {
//    let outcomes: [MutationTestOutcome]
//
//    var appliedOperatorsReport: [AppliedOperatorReportItem] {
//        return outcomes.map {
//            AppliedOperatorReportItem(
//                fileName: URL(fileURLWithPath: $0.filePath).lastPathComponent,
//                position: "Line: \($0.position.line), Column: \($0.position.column)",
//                appliedMutation: $0.appliedMutation,
//                testSuiteResult: $0.testSuiteResult
//            )
//        }
//    }
//
//
//    var mutationScoresReport: [MutationScoreReportItem] {
//        return []
//    }
//}
//
//extension MuterTestReport2 {
//    struct AppliedOperatorReportItem {
//        let fileName: String
//        let position: String
//        let appliedMutation: String
//        let testSuiteResult: TestSuiteResult
//    }
//
//    struct MutationScoreReportItem: Codable {
//        let fileName: String
//        let mutationScore: Int
//        let numberOfAppliedMutationOperators: Int
//    }
//}
//
