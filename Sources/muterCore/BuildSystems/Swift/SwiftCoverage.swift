import Foundation

final class SwiftCoverage: BuildSystemCoverage {
    @Dependency(\.process)
    var process: ProcessFactory

    func run(
        with configuration: MuterConfiguration
    ) -> Result<Coverage, CoverageError> {
        guard runWithCoverageEnabled(using: configuration) != nil,
              let binaryPath = buildDirectory(configuration),
              let testArtifact = xctestExecutable(at: binaryPath),
              let coverageReport = coverageReport(binaryPath, testArtifact)
        else {
            return .failure(.build)
        }

        let projectCoverage = projectCoverage(
            report: coverageReport,
            coverageThreshold: configuration.coverageThreshold
        )

        let functionsCoverage = functionsCoverage(configuration)

        return .success(
            Coverage(
                percent: projectCoverage.percent,
                filesWithoutCoverage: projectCoverage.filesWithoutCoverage,
                functionsCoverage: functionsCoverage
            )
        )
    }

    func buildDirectory(_ configuration: MuterConfiguration) -> String? {
        process().runProcess(
            url: configuration.testCommandExecutable,
            arguments: ["build", "--show-bin-path"]
        )
        .flatMap(\.nilIfEmpty)
        .map(\.trimmed)
    }

    private func projectCoverage(
        report: String,
        coverageThreshold: Double = 0
    ) -> (percent: Int, filesWithoutCoverage: [FilePath]) {
        let files = report.stringsMatchingRegex("^(.)*.swift", options: .anchorsMatchLines)
        var percents = report.split(separator: "\n").compactMap { line in
            String(line)
                .stringsMatchingRegex("\\d{1,3}.\\d{1,2}%")
                .last?
                .replacingOccurrences(of: "%", with: "")
        }.compactMap { Double($0) }

        let percent = Int(percents.removeLast())
        let filesWithoutCoverage = zip(files, percents)
            .include { _, coverage in coverage <= coverageThreshold }
            .map(\.0)

        return (percent: percent, filesWithoutCoverage: filesWithoutCoverage)
    }

    private func coverageReport(
        _ binaryPath: String,
        _ testArtifactPath: String
    ) -> String? {
        let packageTests = URL(fileURLWithPath: testArtifactPath)
            .deletingPathExtension()
            .lastPathComponent

        #if os(Linux)
        let url = "llvm-cov"
        let arguments = [
            "report",
            testArtifactPath,
            "-instr-profile",
            binaryPath + "/codecov/default.profdata",
            "--ignore-filename-regex=.build|Tests"
        ]
        #else
        let url = "/usr/bin/xcrun"
        let arguments = [
            "llvm-cov",
            "report",
            testArtifactPath + "/Contents/MacOS/\(packageTests)",
            "-instr-profile",
            binaryPath + "/codecov/default.profdata",
            "--ignore-filename-regex=.build|Tests"
        ]
        #endif
        return process().runProcess(
            url: url,
            arguments: arguments
        )
        .flatMap(\.nilIfEmpty)
        .map(\.trimmed)
    }
}
