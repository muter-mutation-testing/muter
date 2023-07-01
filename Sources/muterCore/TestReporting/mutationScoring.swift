func mutationScore(from testResults: [TestSuiteOutcome]) -> Int {
    guard !testResults.isEmpty else {
        return -1
    }

    let numberOfFailures = Double(testResults.count { $0 == .failed || $0 == .runtimeError })
    let totalResults = Double(testResults.count { $0 != .buildError })

    guard totalResults > 0 else {
        return 0
    }

    return Int((numberOfFailures / totalResults) * 100.0)
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
