import Foundation
import Rainbow

func generateTestReport(from outcomes: [MutationTestOutcome] ) -> String {
	let finishedRunningMessage = "Muter finished running!\n\n"
	let appliedMutationsTable = generateAppliedMutationsTable(from: outcomes)
	let mutationScoresTable = generateMutationScoresTable(from: outcomes)
	
	let appliedMutationsMessage = """
	--------------------------
	Applied Mutation Operators
	--------------------------
	
	These are all of the ways that Muter introduced changes into your code.
	
	In total, Muter applied \(outcomes.count) mutation operators.
	
	\(appliedMutationsTable)
	
	
	
	"""
	
	let globalScore = mutationScore(from: outcomes.map { $0.testSuiteResult })
	let coloredGlobalScore = coloredMutationScore(for: globalScore, appliedTo: "\(globalScore)/100")
	let mutationScoreMessage = "Mutation Score of Test Suite (higher is better): \(coloredGlobalScore)"
	let mutationScoresMessage = """
	--------------------
	Mutation Test Scores
	--------------------
	
	\(mutationScoreMessage)
	
	\(mutationScoresTable)
	"""
	
	return finishedRunningMessage + appliedMutationsMessage + mutationScoresMessage
}

func generateAppliedMutationsTable(from outcomes: [MutationTestOutcome], coloringFunction: ([Table.Row]) -> [Table.Row] = applyMutationTestResultsColor) -> Table {
	var appliedMutations = [Table.Row]()
	var fileNames = [Table.Row]()
	var positions = [Table.Row]()
	var mutationTestResults = [Table.Row]()
	
	for (fileName, position, appliedMutation, testResult) in outcomes.map(testOutcomesToIndividualValues) {
		appliedMutations.append(appliedMutation)
		fileNames.append(fileName)
		positions.append(position)
		mutationTestResults.append(testResult)
	}
	
	mutationTestResults = coloringFunction(mutationTestResults)
	
	return Table(padding: 3, columns: [
		Table.Column(title: "File", rows: fileNames),
		Table.Column(title: "Position", rows: positions),
		Table.Column(title: "Applied Mutation Operator", rows: appliedMutations),
		Table.Column(title: "Mutation Test Result", rows: mutationTestResults),
	])
}

func testOutcomesToIndividualValues(outcome: MutationTestOutcome) -> (Table.Row, Table.Row, Table.Row, Table.Row) {
	let fileName = URL(string: outcome.filePath)!.lastPathComponent
	return (Table.Row(value: fileName),
			Table.Row(value: "Line: \(outcome.position.line), Column: \(outcome.position.column)"),
			Table.Row(value: outcome.appliedMutation),
			Table.Row(value: outcome.testSuiteResult.asMutationTestOutcome))
}

func generateMutationScoresTable(from outcomes: [MutationTestOutcome], coloringFunction: ([Table.Row]) -> [Table.Row] = applyMutationScoreColor) -> Table {
	var fileNames = [Table.Row]()
	var numberOfAppliedMutations = [Table.Row]()
	var mutationScores = [Table.Row]()
	
	for (filePath, mutationScore) in mutationScoreOfFiles(from: outcomes).sorted(by: ascendingFilenameOrder)  {
		let fileName = URL(string: filePath)!.lastPathComponent
		let appliedMutationsCount = outcomes.filter { $0.filePath == filePath }.count
		
		fileNames.append(Table.Row(value: fileName))
		numberOfAppliedMutations.append(Table.Row(value: "\(appliedMutationsCount)"))
		mutationScores.append(Table.Row(value: "\(mutationScore)"))
	}
	
	mutationScores = coloringFunction(mutationScores)
	
	return Table(padding: 3, columns: [
		Table.Column(title: "File", rows: fileNames),
		Table.Column(title: "# of Applied Mutation Operators", rows: numberOfAppliedMutations),
		Table.Column(title: "Mutation Score", rows: mutationScores),
	])
}

func ascendingFilenameOrder(lhs: (String, Int), rhs: (String, Int)) -> Bool {
	return lhs.0 < rhs.0
}

// MARK - Coloring Functions
func applyMutationTestResultsColor(to rows: [Table.Row]) -> [Table.Row] {
	return rows.map {
		let coloredValue = $0.value == TestSuiteResult.failed.asMutationTestOutcome ?
							$0.value.green :
							$0.value.red
		let coloredRow = Table.Row(value: coloredValue)
		return coloredRow
	}
}

func applyMutationScoreColor(to rows: [Table.Row]) -> [Table.Row] {
	return rows.map {
		let coloredValue = coloredMutationScore(for: Int($0.value)!, appliedTo: $0.value)
		return Table.Row(value: coloredValue)
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
