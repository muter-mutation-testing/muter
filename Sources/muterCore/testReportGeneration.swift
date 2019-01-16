import Foundation
import Rainbow

func generateTestReport(from outcomes: [MutationTestOutcome] ) -> String {
    let finishedRunningMessage = "Muter finished running!\n\n"
    let appliedMutationsCLITable = generateAppliedMutationsCLITable(from: outcomes)
    let mutationScoresCLITable = generateMutationScoresCLITable(from: outcomes)

    let appliedMutationsMessage = """
    --------------------------
    Applied Mutation Operators
    --------------------------

    These are all of the ways that Muter introduced changes into your code.

    In total, Muter applied \(outcomes.count) mutation operators.

    \(appliedMutationsCLITable)



    """

    let globalScore = mutationScore(from: outcomes.map { $0.testSuiteResult })
    let coloredGlobalScore = coloredMutationScore(for: globalScore, appliedTo: "\(globalScore)/100")
    let mutationScoreMessage = "Mutation Score of Test Suite (higher is better): \(coloredGlobalScore)"
    let mutationScoresMessage = """
    --------------------
    Mutation Test Scores
    --------------------

    \(mutationScoreMessage)

    \(mutationScoresCLITable)
    """

    return finishedRunningMessage + appliedMutationsMessage + mutationScoresMessage
}

func generateAppliedMutationsCLITable(from outcomes: [MutationTestOutcome], coloringFunction: ([CLITable.Row]) -> [CLITable.Row] = applyMutationTestResultsColor) -> CLITable {
    var appliedMutations = [CLITable.Row]()
    var fileNames = [CLITable.Row]()
    var positions = [CLITable.Row]()
    var mutationTestResults = [CLITable.Row]()

    for (fileName, position, appliedMutation, testResult) in outcomes.map(testOutcomesToIndividualValues) {
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

func testOutcomesToIndividualValues(outcome: MutationTestOutcome) -> (CLITable.Row, CLITable.Row, CLITable.Row, CLITable.Row) {
    let fileName = URL(fileURLWithPath: outcome.filePath).lastPathComponent
    return (CLITable.Row(value: fileName),
            CLITable.Row(value: "Line: \(outcome.position.line), Column: \(outcome.position.column)"),
            CLITable.Row(value: outcome.appliedMutation),
            CLITable.Row(value: outcome.testSuiteResult.asMutationTestOutcome))
}

func generateMutationScoresCLITable(from outcomes: [MutationTestOutcome], coloringFunction: ([CLITable.Row]) -> [CLITable.Row] = applyMutationScoreColor) -> CLITable {
    var fileNames = [CLITable.Row]()
    var numberOfAppliedMutations = [CLITable.Row]()
    var mutationScores = [CLITable.Row]()

    for (filePath, mutationScore) in mutationScoreOfFiles(from: outcomes).sorted(by: ascendingFilenameOrder)  {
        let fileName = URL(fileURLWithPath: filePath).lastPathComponent
        let appliedMutationsCount = outcomes.filter { $0.filePath == filePath }.count

        fileNames.append(CLITable.Row(value: fileName))
        numberOfAppliedMutations.append(CLITable.Row(value: "\(appliedMutationsCount)"))
        mutationScores.append(CLITable.Row(value: "\(mutationScore)"))
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
        let coloredValue = $0.value == TestSuiteResult.failed.asMutationTestOutcome ?
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
