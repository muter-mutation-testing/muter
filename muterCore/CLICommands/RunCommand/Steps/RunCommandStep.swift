protocol RunCommandStep {
    func run(with state: AnyRunCommandState) -> Result<[RunCommandState.Change], MuterError>
}
