import Foundation

final class SwiftCoverage: BuildSystemCoverage {
    private let makeProcess: ProcessFactory

    init(_ makeProcess: @escaping ProcessFactory) {
        self.makeProcess = makeProcess
    }
    func run(
        process makeProcess: ProcessFactory,
        with configuration: MuterConfiguration
    ) -> Result<Coverage, CoverageError> {
        guard let verboseCoverageOutput = runWithCoverageInVerboseMode(using: configuration),
              let llvmCovExport = extractLlvmCovFrom(verboseCoverageOutput),
              let commands = executableAndArgumentsFrom(llvmCovExport),
              let llvmCovReport = runLlvmCovReport(with: commands) else {
            return .failure(.build)
        }

        let projectCoverage = Coverage.from(report: llvmCovReport)

        return .success(projectCoverage)
    }
    
    private func runWithCoverageInVerboseMode(using configuration: MuterConfiguration) -> String? {
        runProcess(
            makeProcess,
            url: configuration.testCommandExecutable,
            arguments: configuration.testCommandArguments + ["--enable-code-coverage", "--verbose"]
        ).map(\.trimmed)
    }
    
    private func extractLlvmCovFrom(_ output: String) -> String? {
        output.firstMatchOf("^.*llvm-cov export.*$", options: .anchorsMatchLines)
    }
    
    private func executableAndArgumentsFrom(
        _ line: String
    ) -> (executable: String, arguments: String)?
    {
        line.range(of: "llvm-cov")
            .map {
                (executable: String(line.prefix(through: $0.upperBound)).trimmed,
                 arguments: String(line[$0.upperBound..<line.endIndex]).trimmed)
            }
    }
    
    private func runLlvmCovReport(with commands: (executable: String, arguments: String)) -> String? {
        let (executable, arguments) = commands
        let exportArguments = arguments
            .replacingOccurrences(of: "export", with: "report")
            .components(separatedBy: " ")
            .exclude(\.isEmpty) +
            ["--ignore-filename-regex=.build|Tests"]
        
        return runProcess(
            makeProcess,
            url: executable,
            arguments: exportArguments
        )
    }
}

private extension Coverage {
    static func from(report: String) -> Coverage {
        let files = report.stringsMatchingRegex("^(.)*.swift", options: .anchorsMatchLines)
        var percents = report.stringsMatchingRegex("\\d{1,3}.\\d{1,2}%$", options: .anchorsMatchLines)
            .map { $0.replacingOccurrences(of: "%", with: "") }
            .compactMap { Double($0) }

        let percent = percents.removeLast()
        let filesWithoutCoverage = zip(files, percents)
                .include { (_, coverage) in coverage == 0 }
                .map (\.0)
        
        return Coverage(
            percent: Int(percent),
            filesWithoutCoverage: filesWithoutCoverage
        )
    }
}
