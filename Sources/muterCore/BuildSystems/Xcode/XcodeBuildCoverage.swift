import Foundation

final class XcodeBuildCoverage: BuildSystemCoverage {
    @Dependency(\.process)
    var process: ProcessFactory

    func run(
        with configuration: MuterConfiguration
    ) -> Result<Coverage, CoverageError> {
        guard let resultPath = runTestsWithCoverageEnabled(using: configuration),
              let report = runXccov(with: resultPath)
        else {

            return .failure(.build)
        }

        let untested = extractUntested(
            from: report,
            coverageThreshold: configuration.coverageThreshold
        )

        let percent = extractCoverage(from: report)
        let functionsCoverage = functionsCoverage(configuration)

        let projectCoverage = Coverage(
            percent: percent,
            filesWithoutCoverage: untested,
            functionsCoverage: functionsCoverage
        )

        return .success(projectCoverage)
    }

    /// The folder that Muter searches for the test bundle and the profile data.
    ///
    /// - A project or workspace: the parent of `BUILD_DIR` from `-showBuildSettings`, so a custom build
    ///   location set by the project is respected.
    /// - A Swift package: `-showBuildSettings` prints no settings, so `enableCoverageArguments` passes
    ///   `-derivedDataPath`, and that folder is used.
    func buildDirectory(_ configuration: MuterConfiguration) -> String? {
        if configuration.testsSwiftPackageWithXcodebuild {
            return URL(fileURLWithPath: configuration.derivedDataPath).path.nilIfEmpty
        }

        return process().runProcess(
            url: configuration.testCommandExecutable,
            arguments: configuration.testCommandArguments + ["-showBuildSettings"]
        )
        .flatMap(Self.buildDir(inBuildSettings:))
        .flatMap { URL(fileURLWithPath: $0).deletingLastPathComponent().path }
    }

    /// The value of `BUILD_DIR` in `-showBuildSettings` output (`    BUILD_DIR = /path/Build/Products`).
    /// Only the value: the whole line is not a path.
    static func buildDir(inBuildSettings output: String) -> String? {
        let prefix = "BUILD_DIR = "

        return output
            .components(separatedBy: .newlines)
            .map(\.trimmed)
            .first { $0.hasPrefix(prefix) }
            .map { String($0.dropFirst(prefix.count)).trimmed }
            .flatMap(\.nilIfEmpty)
    }

    private func runTestsWithCoverageEnabled(
        using configuration: MuterConfiguration
    ) -> String? {
        process().runProcess(
            url: configuration.testCommandExecutable,
            arguments: configuration.enableCoverageArguments
        )
        .flatMap { $0.firstMatchOf("^.*.xcresult$", options: .anchorsMatchLines) }
        .map(\.trimmed)
        .flatMap(\.nilIfEmpty)
    }

    private func runXccov(with result: String) -> CoverageReport? {
        guard let output: Data = process().runProcess(
            url: process().which("xcrun") ?? "",
            arguments: ["xccov", "view", "--report", "--json", result]
        )
        else {
            return nil
        }

        return try? JSONDecoder().decode(CoverageReport.self, from: output)
    }

    private func extractUntested(
        from report: CoverageReport,
        coverageThreshold: Double
    ) -> [String] {
        report.targets
            .excludeTestTargets()
            .flatMap(\.files)
            .filter { $0.lineCoverage <= coverageThreshold }
            .map(\.path)
    }

    private func extractCoverage(from report: CoverageReport) -> Int {
        report.targets
            .excludeTestTargets()
            .map(\.lineCoverage)
            .map { Int($0 * 100) }
            .first ?? 0
    }
}

private struct CoverageReport: Decodable {
    let targets: [Target]
}

private extension CoverageReport {
    struct Target: Decodable {
        let files: [File]
        let name: String
        let lineCoverage: Double
    }
}

private extension CoverageReport.Target {
    struct File: Decodable {
        let lineCoverage: Double
        let path: String
    }
}

private extension [CoverageReport.Target] {
    func excludeTestTargets() -> [Element] {
        exclude { $0.name.contains("xctest") }
    }
}
