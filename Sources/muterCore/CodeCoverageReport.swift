struct CodeCoverageReport: Equatable, Codable {
    var functionCallCounts: [String: Int] = [:]
}
