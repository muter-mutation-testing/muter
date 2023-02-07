import Foundation

struct ApplySchemata: RunCommandStep {
    private let ioDelegate: MutationTestingIODelegate
    private let notificationCenter: NotificationCenter
    
    init(
        ioDelegate: MutationTestingIODelegate = MutationTestingDelegate(),
        notificationCenter: NotificationCenter = .default
    ) {
        self.ioDelegate = ioDelegate
        self.notificationCenter = notificationCenter
    }
    
    func run(
        with state: AnyRunCommandState
    ) -> Result<[RunCommandState.Change], MuterError> {
        for mutationMap in state.mutationMapping {
            let sourceCode = state.sourceCodeByFilePath[mutationMap.filePath]!
            let rewriter = Rewriter(mutationMap)
            
            let newFile = rewriter.visit(
                sourceCode
            )
            
            try! ioDelegate.writeFile(
                to: mutationMap.filePath,
                contents: newFile.description
            )
            
        }
        
        return .success([])
    }
}
