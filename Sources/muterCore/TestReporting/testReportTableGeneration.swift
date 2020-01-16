import Foundation
import Rainbow
import SwiftSyntax

func generateAppliedMutationOperatorsCLITable(from fileReports: [MuterTestReport.FileReport], coloringFunction: ([CLITable.Row]) -> [CLITable.Row] = applyMutationTestResultsColor) -> CLITable {
    var appliedMutations = [CLITable.Row]()
    var fileNames = [CLITable.Row]()
    var mutationTestResults = [CLITable.Row]()

    for (fileName, appliedMutation, testResult) in fileReports.flatMap(operatorsToTableRows) {
        fileNames.append(fileName)
        appliedMutations.append(appliedMutation)
        mutationTestResults.append(testResult)
    }

    mutationTestResults = coloringFunction(mutationTestResults)

    return CLITable(padding: 3, columns: [
        CLITable.Column(title: "File", rows: fileNames),
        CLITable.Column(title: "Applied Mutation Operator", rows: appliedMutations),
        CLITable.Column(title: "Mutation Test Result", rows: mutationTestResults),
    ])
}

private func operatorsToTableRows(fileReport: MuterTestReport.FileReport) -> [(CLITable.Row, CLITable.Row, CLITable.Row)] {
    return fileReport.appliedOperators.map {
        (CLITable.Row(value: "\(fileReport.fileName):\($0.mutationPoint.position.line)"),
         CLITable.Row(value: $0.mutationPoint.mutationOperatorId.rawValue),
         CLITable.Row(value: $0.testSuiteOutcome.asMutationTestOutcome))
    }
}

func generateMutationScoresCLITable(from fileReports: [MuterTestReport.FileReport], coloringFunction: ([CLITable.Row]) -> [CLITable.Row] = applyMutationScoreColor) -> CLITable {
    var fileNames = [CLITable.Row]()
    var numberOfInsertedMutants = [CLITable.Row]()
    var mutationScores = [CLITable.Row]()

    for fileReport in fileReports  {
        fileNames.append(CLITable.Row(value: fileReport.fileName))
        numberOfInsertedMutants.append(CLITable.Row(value: "\(fileReport.appliedOperators.count)"))
        mutationScores.append(CLITable.Row(value: "\(fileReport.mutationScore)"))
    }

    mutationScores = coloringFunction(mutationScores)

    return CLITable(padding: 3, columns: [
        CLITable.Column(title: "File", rows: fileNames),
        CLITable.Column(title: "# of Introduced Mutants", rows: numberOfInsertedMutants),
        CLITable.Column(title: "Mutation Score", rows: mutationScores),
    ])
}

// MARK: Coloring Functions
func applyMutationTestResultsColor(to rows: [CLITable.Row]) -> [CLITable.Row] {
    return rows.map {
        let coloredValue = $0.value == TestSuiteOutcome.failed.asMutationTestOutcome ?
            $0.value.green :
            $0.value.red
        let coloredRow = CLITable.Row(value: coloredValue)
        return coloredRow
    }
}

func applyMutationScoreColor(to rows: [CLITable.Row]) -> [CLITable.Row] {
    return rows.map {
        let coloredValue = coloredMutationScore(for: Int($0.value)!, appliedTo: $0.value)
        return CLITable.Row(value: coloredValue)
    }
}

func coloredMutationScore(for score: Int, appliedTo text: String) -> String {
    switch score {
    case 0...25:
        return text.red
    case 26...50:
        return text.yellow
    case 51...75:
        return text.lightGreen
    default:
        return text.green
    }
}

// MARK: -

/// Similar to `generateAppliedMutationOperatorsCLITable` but much simplified, intended for displaying dry-run results.
func generateDiscoveredMutationOperatorsCLITable(from mutationPoints: [MutationPoint]) -> CLITable {
    let discoveredMutations = mutationPoints.map { CLITable.Row(value: $0.mutationOperatorId.rawValue) }
    let fileNames = mutationPoints.map { CLITable.Row(value: "\($0.fileName):\($0.position.line)") }

    return CLITable(padding: 3, columns: [
        CLITable.Column(title: "File", rows: fileNames),
        CLITable.Column(title: "Discovered Mutation Operator", rows: discoveredMutations)
        ])
}
