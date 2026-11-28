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
        let buildSettings = buildSettings(configuration)
        let buildDirectory = buildDirectory(configuration, buildSettings: buildSettings)
        let functionsCoverage = functionsCoverage(configuration, buildDirectory: buildDirectory)

        let projectCoverage = Coverage(
            percent: percent,
            filesWithoutCoverage: untested,
            functionsCoverage: functionsCoverage,
            indexStorePath: indexStorePath(configuration, buildSettings: buildSettings)
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
        buildDirectory(configuration, buildSettings: buildSettings(configuration))
    }

    /// The `-showBuildSettings` output of a project or a workspace. Xcode prints no build settings
    /// for a Swift package.
    private func buildSettings(_ configuration: MuterConfiguration) -> String? {
        guard !configuration.testsSwiftPackageWithXcodebuild else {
            return nil
        }

        return process().runProcess(
            url: configuration.testCommandExecutable,
            arguments: configuration.testCommandArguments + ["-showBuildSettings"]
        )
    }

    private func buildDirectory(_ configuration: MuterConfiguration, buildSettings: String?) -> String? {
        if configuration.testsSwiftPackageWithXcodebuild {
            return URL(fileURLWithPath: configuration.derivedDataPath).path.nilIfEmpty
        }

        return buildSettings
            .flatMap(Self.buildDir(inBuildSettings:))
            .flatMap { URL(fileURLWithPath: $0).deletingLastPathComponent().path }
    }

    /// Xcode writes the index store into the derived data folder of the project:
    /// `<DerivedData>/<Project-hash>/Index.noindex/DataStore`. It stays there between runs, as the
    /// build cache does, so a build that compiles nothing still leaves a valid index.
    ///
    /// A project can move its build products (`SYMROOT`) out of derived data, so Muter finds the
    /// folder from `OBJROOT`, `<DerivedData>/<Project-hash>/Build/Intermediates.noindex`. When the
    /// project moves `OBJROOT` too, Muter cannot find the index, and returns `nil`.
    func indexStorePath(_ configuration: MuterConfiguration, buildSettings: String?) -> String? {
        let derivedData: URL
        if configuration.testsSwiftPackageWithXcodebuild {
            derivedData = URL(fileURLWithPath: configuration.derivedDataPath)
        } else {
            guard let objectRoot = buildSettings.flatMap({ Self.buildSetting("OBJROOT", in: $0) }) else {
                return nil
            }
            let intermediates = URL(fileURLWithPath: objectRoot)
            let build = intermediates.deletingLastPathComponent()
            guard intermediates.lastPathComponent == "Intermediates.noindex", build.lastPathComponent == "Build" else {
                return nil
            }
            derivedData = build.deletingLastPathComponent()
        }

        return derivedData.appendingPathComponent("Index.noindex/DataStore").path
    }

    /// The value of `BUILD_DIR` in `-showBuildSettings` output (`    BUILD_DIR = /path/Build/Products`).
    /// Only the value: the whole line is not a path.
    static func buildDir(inBuildSettings output: String) -> String? {
        buildSetting("BUILD_DIR", in: output)
    }

    /// The value of a build setting in `-showBuildSettings` output.
    static func buildSetting(_ name: String, in output: String) -> String? {
        let prefix = name + " = "

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
