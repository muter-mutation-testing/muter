import Foundation

func generateTestReport(from outcomes: [MutationTestOutcome] ) -> String {
	let finishedRunningMessage = "Muter finished running!\n\n"
	let appliedMutationsTable = generateAppliedMutationsTable(from: outcomes)
	let mutationScoresTable = generateMutationScoresTable(from: outcomes)
	
	let appliedMutationsMessage = """
	--------------------------
	Applied Mutation Operators
	--------------------------
	
	These are all of the ways that Muter introduced changes into your code.
	
	\(appliedMutationsTable)
	
	
	
	"""
	
	let globalScore = mutationScore(from: outcomes.map { $0.testSuiteResult })
	let mutationScoreMessage = "Mutation Score of Test Suite (higher is better): \(globalScore)/100"
	let mutationScoresMessage = """
	--------------------
	Mutation Test Scores
	--------------------
	
	\(mutationScoreMessage)
	
	\(mutationScoresTable)
	"""
	
	return finishedRunningMessage + appliedMutationsMessage + mutationScoresMessage
}

func generateAppliedMutationsTable(from outcomes: [MutationTestOutcome]) -> Table {
	var appliedMutations = [Table.Row]()
	var fileNames = [Table.Row]()
	var mutationTestResults = [Table.Row]()
	for (appliedMutation, fileName, testResult) in outcomes.map(testOutcomesToIndividualValues) {
		appliedMutations.append(appliedMutation)
		fileNames.append(fileName)
		mutationTestResults.append(testResult)
	}
	
	return Table(padding: 3, columns: [
		Table.Column(title: "Applied Mutation Operator", rows: appliedMutations),
		Table.Column(title: "File", rows: fileNames),
		Table.Column(title: "Mutation Test Result", rows: mutationTestResults),
	])
}

func testOutcomesToIndividualValues(outcome: MutationTestOutcome) -> (Table.Row, Table.Row, Table.Row) {
	let fileName = URL(string: outcome.filePath)!.lastPathComponent
	return (Table.Row(value: outcome.appliedMutation),
			Table.Row(value: fileName),
			Table.Row(value: outcome.testSuiteResult.asMutationTestingResult))
}

func generateMutationScoresTable(from outcomes: [MutationTestOutcome]) -> Table {
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
	
	return Table(padding: 3, columns: [
		Table.Column(title: "File", rows: fileNames),
		Table.Column(title: "# of Applied Mutation Operators", rows: numberOfAppliedMutations),
		Table.Column(title: "Mutation Score", rows: mutationScores),
	])
}

func ascendingFilenameOrder(lhs: (String, Int), rhs: (String, Int)) -> Bool {
	return lhs.0 < rhs.0
}
