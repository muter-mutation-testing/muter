struct MutationTester {
    let filePaths: [String]
    let mutation: SourceCodeMutation
    let runTestSuite: () -> Void
    let writeFile: (String, String) throws -> Void
    
    func perform() {
        for path in filePaths {
            let sourceCode = FileParser.load(path: path)!
            
            if mutation.canMutate(source: sourceCode) {
                let mutatedSourceCode = mutation.mutate(source: sourceCode)
                try! writeFile(path, mutatedSourceCode.description)
                runTestSuite()
            }
        }
    }
}
