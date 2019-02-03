import Foundation
import Rainbow
import SwiftSyntax

//extension MuterTestReport2: CustomStringConvertible {
//
//    var description: String {
//        let finishedRunningMessage = "Muter finished running!\n\n"
//        let appliedMutationsCLITable = generateAppliedMutationsCLITable(from: self)
//        let mutationScoresCLITable = generateMutationScoresCLITable(from: self)
//
//        let appliedMutationsMessage = """
//        --------------------------
//        Applied Mutation Operators
//        --------------------------
//
//        These are all of the ways that Muter introduced changes into your code.
//
//        In total, Muter applied \(outcomes.count) mutation operators.
//
//        \(appliedMutationsCLITable)
//
//
//
//        """
//
//        let coloredGlobalScore = coloredMutationScore(for: self.globalMutationScore, appliedTo: "\(self.globalMutationScore)/100")
//        let mutationScoreMessage = "Mutation Score of Test Suite (higher is better)".bold + ": \(coloredGlobalScore)"
//        let mutationScoresMessage = """
//        --------------------
//        Mutation Test Scores
//        --------------------
//
//        These are the mutation scores for your test suite, as well as the files that had mutants introduced into them.
//
//        Mutation scores ignore build & runtime errors.
//
//        \(mutationScoreMessage)
//
//        \(mutationScoresCLITable)
//        """
//
//        return finishedRunningMessage + appliedMutationsMessage + mutationScoresMessage
//    }
//
//}

func generateAppliedMutationsCLITable(from fileReports: [MuterTestReport.FileReport], coloringFunction: ([CLITable.Row]) -> [CLITable.Row] = applyMutationTestResultsColor) -> CLITable {
    var appliedMutations = [CLITable.Row]()
    var fileNames = [CLITable.Row]()
    var positions = [CLITable.Row]()
    var mutationTestResults = [CLITable.Row]()

    for (fileName, position, appliedMutation, testResult) in fileReports.map(operatorsToTableRows) {
        appliedMutations.append(appliedMutation)
        fileNames.append(fileName)
        positions.append(position)
        mutationTestResults.append(testResult)
    }

    mutationTestResults = coloringFunction(mutationTestResults)

    return CLITable(padding: 3, columns: [
        CLITable.Column(title: "File", rows: fileNames),
        CLITable.Column(title: "Position", rows: positions),
        CLITable.Column(title: "Applied Mutation Operator", rows: appliedMutations),
        CLITable.Column(title: "Mutation Test Result", rows: mutationTestResults),
    ])
}

func operatorsToTableRows(fileReport: MuterTestReport.FileReport) -> (CLITable.Row, CLITable.Row, CLITable.Row, CLITable.Row) {
    return (CLITable.Row(value: fileReport.fileName), CLITable.Row(value: fileReport.fileName), CLITable.Row(value: fileReport.fileName), CLITable.Row(value: fileReport.fileName))
//            CLITable.Row(value: item.position),
//            CLITable.Row(value: item.appliedMutation.rawValue),
//            CLITable.Row(value: item.testSuiteResult.asMutationTestOutcome))
}

func generateMutationScoresCLITable(from fileReports: [MuterTestReport.FileReport], coloringFunction: ([CLITable.Row]) -> [CLITable.Row] = applyMutationScoreColor) -> CLITable {
    var fileNames = [CLITable.Row]()
    var numberOfAppliedMutations = [CLITable.Row]()
    var mutationScores = [CLITable.Row]()

    for mutationScoreReport in fileReports  {

        fileNames.append(CLITable.Row(value: mutationScoreReport.fileName))
//        numberOfAppliedMutations.append(CLITable.Row(value: "\(mutationScoreReport.numberOfAppliedMutationOperators)"))
        mutationScores.append(CLITable.Row(value: "\(mutationScoreReport.mutationScore)"))
    }

    mutationScores = coloringFunction(mutationScores)

    return CLITable(padding: 3, columns: [
        CLITable.Column(title: "File", rows: fileNames),
        CLITable.Column(title: "# of Applied Mutation Operators", rows: numberOfAppliedMutations),
        CLITable.Column(title: "Mutation Score", rows: mutationScores),
    ])
}

func ascendingFilenameOrder(lhs: (String, Int), rhs: (String, Int)) -> Bool {
    return lhs.0 < rhs.0
}

// MARK - Coloring Functions
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

private func coloredMutationScore(for score: Int, appliedTo text: String) -> String {
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
