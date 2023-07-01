import Foundation

final class SwiftCoverage: BuildSystemCoverage {
    @Dependency(\.process)
    var process: ProcessFactory

    func run(
        with configuration: MuterConfiguration
    ) -> Result<Coverage, CoverageError> {
        guard runWithCoverageEnabled(using: configuration) != nil,
              let binaryPath = binaryPath(configuration),
              let testArtifact = findTestArtifact(binaryPath),
              let coverageReport = coverageReport(testArtifact)
        else {
            return .failure(.build)
        }

        let projectCoverage = Coverage.from(report: coverageReport)

        return .success(projectCoverage)
    }

    private func runWithCoverageEnabled(
        using configuration: MuterConfiguration
    ) -> String? {
        process().runProcess(
            url: configuration.testCommandExecutable,
            arguments: configuration.enableCoverageArguments
        ).map(\.trimmed)
    }

    private func binaryPath(
        _ configuration: MuterConfiguration
    ) -> String? {
        process().runProcess(
            url: configuration.testCommandExecutable,
            arguments: ["build", "--show-bin-path"]
        )
        .flatMap(\.nilIfEmpty)
        .map(\.trimmed)
    }

    private func findTestArtifact(
        _ binaryPath: String
    ) -> String? {
        process().runProcess(
            url: "/usr/bin/find",
            arguments: [binaryPath, "-name", "*.xctest"]
        )
        .flatMap(\.nilIfEmpty)
        .map(\.trimmed)
    }

    private func coverageReport(
        _ testArtifactPath: String
    ) -> String? {
        let packageTests = URL(fileURLWithPath: testArtifactPath)
            .deletingPathExtension()
            .lastPathComponent

        return process().runProcess(
            url: "/usr/bin/xcrun",
            arguments: [
                "llvm-cov",
                "report",
                testArtifactPath + "/Contents/MacOS/\(packageTests)",
                "-instr-profile",
                ".build/debug/codecov/default.profdata",
                "--ignore-filename-regex=.build|Tests"
            ]
        )
        .flatMap(\.nilIfEmpty)
        .map(\.trimmed)
    }
}

private extension Coverage {
    static func from(report: String) -> Coverage {
        let files = report.stringsMatchingRegex("^(.)*.swift", options: .anchorsMatchLines)
        var percents = report.split(separator: "\n").compactMap { line in
            String(line)
                .stringsMatchingRegex("\\d{1,3}.\\d{1,2}%")
                .last?
                .replacingOccurrences(of: "%", with: "")
        }.compactMap { Double($0) }

        let percent = percents.removeLast()
        let filesWithoutCoverage = zip(files, percents)
            .include { _, coverage in coverage == 0 }
            .map(\.0)

        return Coverage(
            percent: Int(percent),
            filesWithoutCoverage: filesWithoutCoverage
        )
    }
}
