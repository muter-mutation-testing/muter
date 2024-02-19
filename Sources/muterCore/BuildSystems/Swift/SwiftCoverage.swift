import Foundation

final class SwiftCoverage: BuildSystemCoverage {
    @Dependency(\.process)
    var process: ProcessFactory

    func run(
        with configuration: MuterConfiguration
    ) -> Result<Coverage, CoverageError> {
        guard runWithCoverageEnabled(using: configuration) != nil else {
            return .failure(.build)
        }
        
        guard let binaryPath = binaryPath(configuration) else {
            return .failure(.build)
        }
        
        guard let testArtifact = findTestArtifact(binaryPath) else {
            return .failure(.build)
        }
        
        guard let testArtifact = findTestArtifact(binaryPath) else {
            return .failure(.build)
        }
        
        guard let coverageReport = coverageReport(binaryPath, testArtifact) else {
            return .failure(.build)
        }
//        guard runWithCoverageEnabled(using: configuration) != nil,
//              let binaryPath = binaryPath(configuration),
//              let testArtifact = findTestArtifact(binaryPath),
//              let coverageReport = coverageReport(binaryPath, testArtifact)
//        else {
//            return .failure(.build)
//        }

        let projectCoverage: Coverage = .from(
            report: coverageReport,
            coverageThreshold: configuration.coverageThreshold
        )

        return .success(projectCoverage)
    }

    private func runWithCoverageEnabled(
        using configuration: MuterConfiguration
    ) -> String? {
        let result: String? = process().runProcess(
            url: configuration.testCommandExecutable,
            arguments: configuration.enableCoverageArguments
        )
        .flatMap(\.nilIfEmpty)
        .map(\.trimmed)
        
        return result
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
        let result = process().runProcess(
            url: "/usr/bin/find",
            arguments: [binaryPath, "-name", "*.xctest"]
        )
        .flatMap(\.nilIfEmpty)
        .map(\.trimmed)

        return result
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

private extension Coverage {
    static func from(
        report: String,
        coverageThreshold: Double = 0
    ) -> Coverage {
        let files = report.stringsMatchingRegex("^(.)*.swift", options: .anchorsMatchLines)
        var percents = report.split(separator: "\n").compactMap { line in
            String(line)
                .stringsMatchingRegex("\\d{1,3}.\\d{1,2}%")
                .last?
                .replacingOccurrences(of: "%", with: "")
        }.compactMap { Double($0) }

        let percent = percents.removeLast()
        let filesWithoutCoverage = zip(files, percents)
            .include { _, coverage in coverage <= coverageThreshold }
            .map(\.0)

        return Coverage(
            percent: Int(percent),
            filesWithoutCoverage: filesWithoutCoverage
        )
    }
}
