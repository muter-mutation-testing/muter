import Foundation

enum BuildSystem: String, Codable, Equatable {
    case xcodebuild
    case swift
    case unknown

    init(rawValue: String) {
        switch rawValue {
        case "swift": self = .swift
        case "xcodebuild": self = .xcodebuild
        default: self = .unknown
        }
    }
}

extension BuildSystem {
    static func coverage(
        for buildSystem: BuildSystem
    ) -> BuildSystemCoverage? {
        switch buildSystem {
        case .swift: return SwiftCoverage()
        case .xcodebuild: return XcodeBuildCoverage()
        default: return nil
        }
    }
}

protocol BuildSystemCoverage: AnyObject {
    var process: ProcessFactory { get }

    func run(
        with configuration: MuterConfiguration
    ) -> Result<Coverage, CoverageError>

    func buildDirectory(_ configuration: MuterConfiguration) -> String?
}

extension BuildSystemCoverage {
    func runWithCoverageEnabled(using configuration: MuterConfiguration) -> String? {
        let result: String? = process().runProcess(
            url: configuration.testCommandExecutable,
            arguments: configuration.enableCoverageArguments
        )
        .flatMap(\.nilIfEmpty)
        .map(\.trimmed)

        return result
    }

    func functionsCoverage(_ configuration: MuterConfiguration) -> FunctionsCoverage {
        functionsCoverage(configuration, buildDirectory: buildDirectory(configuration))
    }

    func functionsCoverage(_ configuration: MuterConfiguration, buildDirectory: String?) -> FunctionsCoverage {
        guard let buildDirectory else {
            CoverageDiagnostics.warn("The build directory was not found.")
            return .null
        }
        CoverageDiagnostics.debug("build directory: \(buildDirectory)")

        guard let xctestExecutable = xctestExecutable(at: buildDirectory) else {
            CoverageDiagnostics.warn("No .xctest bundle was found in \(buildDirectory).")
            return .null
        }
        CoverageDiagnostics.debug("xctest bundle: \(xctestExecutable)")

        guard let testBinary = testBinary(at: xctestExecutable) else {
            CoverageDiagnostics.warn("No test binary was found in \(xctestExecutable).")
            return .null
        }
        CoverageDiagnostics.debug("test binary: \(testBinary)")

        guard let testProfile = testProfileData(at: buildDirectory) else {
            CoverageDiagnostics.warn("No .profdata file was found in \(buildDirectory).")
            return .null
        }
        CoverageDiagnostics.debug("profile data: \(testProfile)")

        guard let reportJson = llvmCovJsonReport(
            withExecutableAt: testBinary,
            coverageProfile: testProfile
        )
        else {
            CoverageDiagnostics.warn("llvm-cov export gave no output for \(testBinary).")
            return .null
        }
        CoverageDiagnostics.debug("llvm-cov export: \(reportJson.count) bytes")

        let coverageData: LLVMCoverage
        do {
            coverageData = try JSONDecoder().decode(LLVMCoverage.self, from: reportJson)
        } catch {
            CoverageDiagnostics.warn("The llvm-cov export could not be decoded: \(error)")
            return .null
        }

        return FunctionsCoverage(from: coverageData)
    }

    func xctestExecutable(at buildDirectory: String) -> String? {
        process().find(atPath: buildDirectory, byName: "*.xctest")
            .flatMap { firstPath(in: $0) }
    }

    /// The test executable inside the `.xctest` bundle. Since Xcode 26, SwiftPM also puts the
    /// debug symbols in the bundle (`Contents/MacOS/<name>.dSYM/Contents/Resources/DWARF/<name>`),
    /// and that file has the same name. `llvm-cov` needs the executable, so files inside a
    /// `.dSYM` are skipped.
    func testBinary(at path: String) -> String? {
        let url = URL(fileURLWithPath: path)
        let name = url.deletingPathExtension().lastPathComponent

        return process().findExecutable(atPath: url.path, byName: name)
            .flatMap { firstPath(in: $0) { !$0.contains(".dSYM/") } }
    }

    /// `find` prints one path per line. Two paths joined by a newline are not a path.
    private func firstPath(
        in findOutput: String,
        where isIncluded: (String) -> Bool = { _ in true }
    ) -> String? {
        findOutput
            .components(separatedBy: "\n")
            .map(\.trimmed)
            .first { !$0.isEmpty && isIncluded($0) }
    }

    func testProfileData(at path: String) -> String? {
        guard let profiles = process().find(atPath: path, byName: "*.profdata") else {
            return nil
        }

        let lines = profiles.components(separatedBy: "\n")

        return lines.first ?? profiles.trimmed
    }

    /// The `llvm-cov export` JSON, as the process wrote it. The report can be hundreds of megabytes
    /// for a large app, so it stays `Data`: each conversion to a `String` and back made a full copy.
    func llvmCovJsonReport(withExecutableAt executablePath: String, coverageProfile: String) -> Data? {
        #if os(Linux)
        let url = process().which("llvm-cov")
        let arguments = [
            "export",
            executablePath,
            "-instr-profile",
            coverageProfile,
            "--ignore-filename-regex=.build|Tests",
        ]
        #else
        let url = process().which("xcrun")
        let arguments = [
            "llvm-cov",
            "export",
            executablePath,
            "-instr-profile",
            coverageProfile,
            "--ignore-filename-regex=.build|Tests",
        ]
        #endif
        let report: Data? = process().runProcess(
            url: url ?? "",
            arguments: arguments
        )
        return report.flatMap { $0.isEmpty ? nil : $0 }
    }
}

enum CoverageError: Error {
    case build
}
