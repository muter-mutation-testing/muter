import Foundation

struct PrepareSourceCode {
    @Dependency(\.writeFile)
    private var writeFile: WriteFile
    @Dependency(\.loadSourceCode)
    private var loadSourceCode: LoadSourceCode
    
    func prepareSourceCode(
        _ path: String
    ) -> PreparedSourceCode? {
        guard let source = loadSourceCode(path) else {
            return nil
        }

        let addImport = AddImportRewriter()
        let addImportSource = addImport.visit(source.code)
        
        let disableLinters = DisableLintersRewriter()
        let disableLintersSource = disableLinters.visit(addImportSource)
        
        let newSourceCode = disableLintersSource.description
        
        let numberOfNewLines = addImport.newLinesAddedToFile + disableLinters.newLinesAddedToFile
        let changes = MutationSourceCodePreparationChange(
            newLines: numberOfNewLines
        )

        do {
            try writeFile(
                newSourceCode,
                path
            )
            
            return loadSourceCode(path)
                .map { sourceCode in
                    return PreparedSourceCode(
                        source: sourceCode,
                        changes: changes
                    )
                }
        } catch {
            return nil
        }
    }
}

