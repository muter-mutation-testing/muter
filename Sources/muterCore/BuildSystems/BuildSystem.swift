import Foundation

enum BuildSystem: String {
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
        case .xcodebuild: return XcodeCoverage()
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
        guard let buildDirectory = buildDirectory(configuration) else {
            return .null
        }

        guard let xctestExecutable = xctestExecutable(at: buildDirectory) else {
            return .null
        }

        guard let testBinary = testBinary(at: xctestExecutable) else {
            return .null
        }

        guard let testProfile = testProfileData(at: buildDirectory) else {
            return .null
        }

        guard let reportJson = llvmCovJsonReport(
            withExecutableAt: testBinary,
            coverageProfile: testProfile
        )?.data(using: .utf8)
        else {
            return .null
        }

        guard let coverageData = try? JSONDecoder().decode(LLVMCoverage.self, from: reportJson) else {
            return .null
        }

        return FunctionsCoverage(from: coverageData)
    }

    func xctestExecutable(at buildDirectory: String) -> String? {
        process().find(atPath: buildDirectory, byName: "*.xctest").map(\.trimmed)
    }

    func testBinary(at path: String) -> String? {
        let url = URL(fileURLWithPath: path)
        let name = url.deletingPathExtension().lastPathComponent

        return process().findExecutable(atPath: url.path, byName: name)
    }

    func testProfileData(at path: String) -> String? {
        guard let profiles = process().find(atPath: path, byName: "*.profdata") else {
            return nil
        }

        let lines = profiles.components(separatedBy: "\n")

        return lines.first ?? profiles.trimmed
    }

    func llvmCovJsonReport(withExecutableAt executablePath: String, coverageProfile: String) -> String? {
        #if os(Linux)
        let url = "llvm-cov"
        let arguments = [
            "export",
            executablePath,
            "-instr-profile",
            coverageProfile,
            "--ignore-filename-regex=.build|Tests",
        ]
        #else
        let url = "/usr/bin/xcrun"
        let arguments = [
            "llvm-cov",
            "export",
            executablePath,
            "-instr-profile",
            coverageProfile,
            "--ignore-filename-regex=.build|Tests",
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

enum CoverageError: Error {
    case build
}
