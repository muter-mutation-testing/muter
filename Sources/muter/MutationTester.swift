struct MutationTester {
    let configuration: MuterConfiguration
    let filePaths: [String]
    let mutation: SourceCodeMutation
    let runTestSuite: (String, [String]) -> Void
    let writeFile: (String, String) throws -> Void
    
    func perform() {
        for path in filePaths {
            let sourceCode = FileParser.load(path: path)!
            let mutatedSourceCode = mutation.mutate(source: sourceCode)
            runTestSuite(configuration.testCommandExecutable,
                         configuration.testCommandArguments)
            try! writeFile(path, mutatedSourceCode.description)
        }
    }
}
