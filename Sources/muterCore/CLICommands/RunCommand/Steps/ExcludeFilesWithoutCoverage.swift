import Foundation

protocol Launchable: AnyObject {
    var executableURL: URL? { get set }
    var arguments: [String]? { get set }
    var standardOutput: Any? { get set }
    
    func run() throws
    func waitUntilExit()
}

extension Process: Launchable {
    var stdout: StandardOutput? { standardOutput as? StandardOutput }
}

protocol StandardOutput {
    func data() -> Data?
}

extension Pipe: StandardOutput {
    func data() -> Data? {
        if #available(OSX 10.15.4, *) {
            return try? fileHandleForReading.readToEnd()
        } else {
            return fileHandleForReading.readDataToEndOfFile()
        }
    }
}

struct DiscoverFilesWithoutCoverage: RunCommandStep {
    private let process: Launchable
    
    init(process: Launchable = Process()) {
        self.process = process

        process.standardOutput = Pipe()
    }
    
    func run(with state: AnyRunCommandState) -> Result<[RunCommandState.Change], MuterError> {
        guard let resultPath = runWithCoverage(using: state.muterConfiguration),
              let xccovPath = runXcodeSelect(),
              let coverage = runXccov(path: xccovPath, with: resultPath) else {
            return .success([
                .filesWithoutCoverage([])
            ])
        }

        let untested = extractUntested(from: coverage)

        return .success([
            .filesWithoutCoverage(untested)
        ])
    }
    
    private func runWithCoverage(using configuration: MuterConfiguration) -> String? {
        run(
            url: configuration.testCommandExecutable,
            arguments: configuration.testCommandArguments + ["-enableCodeCoverage", "YES"],
            toString
        ).flatMap { $0.firstMatch("^.*.xcresult$") }
         .flatMap(notEmpty)
    }

    private func runXcodeSelect() -> String? {
        run(
            url: "/usr/bin/xcode-select",
            arguments: ["-p"],
            toString
        ).flatMap(notEmpty)
         .map(\.trimmed)
    }
    
    private func runXccov(path: String, with result: String) -> CoverageReport? {
        run(
            url: path + "/usr/bin/xccov",
            arguments: ["view", "--report", "--json", result]
        ) { try? JSONDecoder().decode(CoverageReport.self, from: $0) }
    }
    
    private func extractUntested(from coverage: CoverageReport) -> [String] {
        coverage.targets
            .flatMap(\.files)
            .filter { $0.coveredLines == 0 }
            .map(\.path)
    }
    
    private func run<A>(
        url: String,
        arguments: [String],
        _ transform: (Data) -> A?
    ) -> A? {
        process.executableURL = URL(fileURLWithPath: url)
        process.arguments = arguments

        try? process.run()
        process.waitUntilExit()

        let standardOutput = process.standardOutput as? StandardOutput

        return standardOutput?.data().flatMap(transform)
    }
    
    private func toString(_ data: Data) -> String? {
        String(data: data, encoding: .utf8)
    }
    
    private func notEmpty(_ input: String) -> String? {
        !input.isEmpty ? input : nil
    }
    
    private func firstMatch(in input: String, _ regex: String) -> String? {
        guard let regex = try? NSRegularExpression(
                pattern: regex,
                options: .anchorsMatchLines),
              let result = regex.firstMatch(
                in: input,
                options: [],
                range: .init(location: 0, length: utf8.count)),
              let range = Range(result.range, in: input) else {
            return nil
        }

        return String(input[range])
    }
}

private struct CoverageReport: Decodable {
    let targets: [Target]
}

private extension CoverageReport {
    struct Target: Decodable {
        let files: [File]
    }
}

private extension CoverageReport.Target {
    struct File: Decodable {
        let coveredLines: Int
        let path: String
    }
}
