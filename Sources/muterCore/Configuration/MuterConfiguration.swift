import Foundation
import Yams

struct MuterConfiguration: Equatable, Codable {
    let testCommandArguments: [String]
    let testCommandExecutable: String
    /// File exclusion list.
    let excludeFileList: [String]
    /// Exclusion list of functions for Remove Side Effects.
    let excludeCallList: [String]
    let coverageThreshold: Double
    let buildPath: String

    var buildSystem: BuildSystem {
        guard let buildSystem = testCommandExecutable.components(separatedBy: "/").last?.trimmed else {
            return .unknown
        }

        return BuildSystem(rawValue: buildSystem)
    }

    enum CodingKeys: String, CodingKey {
        case testCommandArguments = "arguments"
        case testCommandExecutable = "executable"
        case excludeFileList = "exclude"
        case excludeCallList = "excludeCalls"
        case coverageThreshold
        case buildPath
    }

    init(
        executable: String = "",
        arguments: [String] = [],
        excludeList: [String] = [],
        excludeCallList callList: [String] = [],
        coverageThreshold threshold: Double = 0,
        buildPath: String = Self.defaultBuildPath
    ) {
        testCommandExecutable = executable
        testCommandArguments = arguments
        excludeFileList = excludeList
        excludeCallList = callList
        coverageThreshold = threshold
        self.buildPath = buildPath
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        testCommandExecutable = try container.decode(String.self, forKey: .testCommandExecutable)
        testCommandArguments = try container.decode([String].self, forKey: .testCommandArguments)

        excludeFileList = container.decode([String].self, default: [], forKey: .excludeFileList)
        excludeCallList = container.decode([String].self, default: [], forKey: .excludeCallList)
        coverageThreshold = container.decode(Double.self, default: 0, forKey: .coverageThreshold)
        buildPath = container.decode(String.self, default: Self.defaultBuildPath, forKey: .buildPath)
    }

    init(from data: Data) throws {
        do {
            self = try YAMLDecoder().decode(MuterConfiguration.self, from: data)
        } catch {
            self = try JSONDecoder().decode(MuterConfiguration.self, from: data)
        }
    }
}

extension MuterConfiguration {
    static let fileName = "muter.conf"
    static let `extension` = "yml"
    static let fileNameWithExtension = "\(fileName).\(`extension`)"
    static let legacyFileNameWithExtension = "\(fileName).json"
    static let defaultBuildPath = ".build"
}

extension MuterConfiguration {
    var asData: Data {
        let encoder = YAMLEncoder()
        return (try! encoder.encode(self)).data(using: .utf8)!
    }
}

extension MuterConfiguration {
    var buildPathArguments: [String] {
        switch buildSystem {
        case .xcodebuild:
            return ["-derivedDataPath", buildPath]
        case .swift:
            return ["--build-path", buildPath]
        case .unknown:
            return []
        }
    }

    var enableCoverageArguments: [String] {
        let arguments = testCommandArguments + buildPathArguments

        switch buildSystem {
        case .xcodebuild:
            return arguments + ["-enableCodeCoverage", "YES"]
        case .swift:
            return arguments + ["--enable-code-coverage"]

        case .unknown:
            return arguments
        }
    }

    var buildForTestingArguments: [String] {
        let arguments = testCommandArguments

        switch buildSystem {
        case .xcodebuild:
            return arguments.dropLast() + ["clean", "build-for-testing"] + buildPathArguments
        case .swift,
                .unknown:
            return arguments + buildPathArguments
        }
    }

    func testWithoutBuildArguments(with testRunFile: String) -> [String] {
        let arguments = testCommandArguments
        switch buildSystem {
        case .xcodebuild:
            guard let destinationIndex = arguments.firstIndex(of: "-destination") else {
                return arguments
            }
            return [
                "test-without-building",
                testCommandArguments[destinationIndex],
                testCommandArguments[destinationIndex.advanced(by: 1)],
                "-xctestrun",
                testRunFile,
            ] + buildPathArguments
        case .swift:
            return arguments + ["--skip-build"] + buildPathArguments
        case .unknown:
            return arguments
        }
    }
}
