/// The percentage of killed mutants, rounded to the nearest whole number. Build errors and ignored
/// mutants do not count.
func mutationScore(from testResults: [TestSuiteOutcome]) -> Int {
    guard !testResults.isEmpty else {
        return -1
    }

    let numberOfKilledMutants = Double(testResults.count(where: \.isKilled))
    let totalResults = Double(testResults.count { $0 != .buildError && $0 != .ignored })

    guard totalResults > 0 else {
        return 0
    }

    return Int((numberOfKilledMutants / totalResults * 100).rounded())
}

func mutationScoresOfFiles(from outcomes: [MutationTestOutcome.Mutation]) -> [String: Int] {
    var mutationScores: [String: Int] = [:]

    let filePaths = outcomes.map { $0.point.filePath }.deduplicated()
    for filePath in filePaths {
        let testSuiteOutcomes = outcomes.include { $0.point.filePath == filePath }.map { $0.testSuiteOutcome }
        mutationScores[filePath] = mutationScore(from: testSuiteOutcomes)
    }

    return mutationScores
}
