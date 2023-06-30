import Foundation
import Progress

#if DEBUG
var current = World()
#else
let current = World()
#endif

typealias ProgressBarInitializer = (
    Int,
    [ProgressElementType]?,
    ProgressBarPrinter?
) -> ProgressBar

typealias PreparedSourceCode = (
    source: SourceCodeInfo,
    changes: MutationSourceCodePreparationChange
)
typealias SourceCodePreparation = (String) -> PreparedSourceCode?
typealias ProcessFactory = () -> Process
typealias Flush = () -> Void
typealias Printer = (String) -> Void
typealias WriteFile = (String, String) throws -> Void
typealias LoadSourceCode = (String) -> SourceCodeInfo?
typealias ProjectCoverage = (BuildSystem) -> BuildSystemCoverage?

struct World {
    var notificationCenter: NotificationCenter = .default
    var fileManager: FileSystemManager = FileManager.default
    var flushStandardOut: Flush = { fflush(stdout) }
    var logger: Logger = .init()
    var printer: Printer = { print($0) }
    var progressBar: ProgressBarInitializer = {
        ProgressBar(
            count: $0,
            configuration: $1,
            printer: $2
        )
    }

    var ioDelegate: MutationTestingIODelegate = MutationTestingDelegate()
    var process: ProcessFactory = Process.Factory.makeProcess
    var prepareCode: SourceCodePreparation = PrepareSourceCode().prepareSourceCode
    var writeFile: WriteFile = { try $0.write(toFile: $1, atomically: true, encoding: .utf8) }
    var loadSourceCode: LoadSourceCode = { sourceCode(fromFileAt: $0) }
    var projectCoverage: ProjectCoverage = BuildSystem.coverage
}
