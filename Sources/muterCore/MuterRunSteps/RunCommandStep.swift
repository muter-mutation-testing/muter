protocol RunCommandStep {
    func run(with state: AnyRunCommandState) async throws -> [RunCommandState.Change]
}
