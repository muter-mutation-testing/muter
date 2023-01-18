import Foundation

final class XcodeCoverage: BuildSystemCoverage {
    private let makeProcess: ProcessFactory

    init(_ makeProcess: @escaping ProcessFactory) {
        self.makeProcess = makeProcess
    }

    func run(
        process makeProcess: ProcessFactory,
        with configuration: MuterConfiguration
    ) -> Result<Coverage, CoverageError> {
        guard let resultPath = runTestsWithCoverageEnabled(using: configuration),
              let xccovPath = runXcodeSelect(),
              let report = runXccov(path: xccovPath, with: resultPath) else {

            return .failure(.build)
        }

        let untested = extractUntested(from: report)
        let percent = extractCoverage(from: report)
        let projectCoverage = Coverage(
            percent: percent,
            filesWithoutCoverage: untested
        )
        
        return .success(projectCoverage)
    }
    
    private func runTestsWithCoverageEnabled(
        using configuration: MuterConfiguration
    ) -> String? {
        runProcess(
            makeProcess,
            url: configuration.testCommandExecutable,
            arguments: configuration.testCommandArguments + ["-enableCodeCoverage", "YES"]
        )
        .flatMap { $0.firstMatchOf("^.*.xcresult$", options: .anchorsMatchLines) }
        .map(\.trimmed)
        .flatMap(\.nilIfEmpty)
    }

    private func runXcodeSelect() -> String? {
        runProcess(
            makeProcess,
            url: "/usr/bin/xcode-select",
            arguments: ["-p"]
        )
        .map(\.trimmed)
        .flatMap(\.nilIfEmpty)
    }
    
    private func runXccov(path: String, with result: String) -> CoverageReport? {
        guard let output: Data = runProcess(
            makeProcess,
            url: path + "/usr/bin/xccov",
            arguments: ["view", "--report", "--json", result]
        ) else {
            return nil
        }

        return try? JSONDecoder().decode(CoverageReport.self, from: output)
    }
    
    private func extractUntested(from report: CoverageReport) -> [String] {
        report.targets
            .excludeTestTargets()
            .flatMap(\.files)
            .filter { $0.coveredLines == 0 }
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
        let coveredLines: Int
        let path: String
    }
}

private extension Array where Element == CoverageReport.Target {
    func excludeTestTargets() -> [Element] {
        exclude { $0.name.contains("xctest") }
    }
}
