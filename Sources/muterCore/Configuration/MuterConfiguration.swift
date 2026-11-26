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
    let testSuiteTimeout: Double?
    /// How many mutants to test at once (`mutationTestWorkers:`). Each worker runs the test command in
    /// its own clone of the mutated project, because `swift test` locks the package's build directory.
    /// Only SwiftPM projects run in parallel; nil or 1 tests one mutant at a time.
    let mutationTestWorkers: Int?
    /// Optional explicit build system from the `buildSystem:` config key. When set it overrides the
    /// executable-basename heuristic — needed when `executable` is a wrapper script (e.g. one that
    /// restores env / forwards SIMCTL_CHILD_ vars) whose filename isn't literally `xcodebuild`/`swift`.
    let explicitBuildSystem: BuildSystem?

    var buildSystem: BuildSystem {
        if let explicitBuildSystem, explicitBuildSystem != .unknown {
            return explicitBuildSystem
        }

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
        case testSuiteTimeout = "mutationTestTimeout"
        case mutationTestWorkers
        case explicitBuildSystem = "buildSystem"
    }

    init(
        executable: String = "",
        arguments: [String] = [],
        excludeList: [String] = [],
        excludeCallList callList: [String] = [],
        coverageThreshold threshold: Double = 0,
        testSuiteTimeOut timeout: Double? = nil,
        mutationTestWorkers workers: Int? = nil,
        buildSystem: BuildSystem? = nil
    ) {
        testCommandExecutable = executable
        testCommandArguments = arguments
        excludeFileList = excludeList
        excludeCallList = callList
        coverageThreshold = threshold
        testSuiteTimeout = timeout
        mutationTestWorkers = workers
        explicitBuildSystem = buildSystem
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        testCommandExecutable = try container.decode(String.self, forKey: .testCommandExecutable)
        testCommandArguments = try container.decode([String].self, forKey: .testCommandArguments)

        excludeFileList = container.decode([String].self, default: [], forKey: .excludeFileList)
        excludeCallList = container.decode([String].self, default: [], forKey: .excludeCallList)
        coverageThreshold = container.decode(Double.self, default: 0, forKey: .coverageThreshold)
        testSuiteTimeout = try container.decodeIfPresent(Double.self, forKey: .testSuiteTimeout)
            ?? (try container.decodeIfPresent(Int.self, forKey: .testSuiteTimeout)).flatMap(Double.init)
        mutationTestWorkers = try container.decodeIfPresent(Int.self, forKey: .mutationTestWorkers)
        explicitBuildSystem = (try container.decodeIfPresent(String.self, forKey: .explicitBuildSystem))
            .map(BuildSystem.init(rawValue:))
    }

    /// The number of mutants to test at once: `mutationTestWorkers` for a SwiftPM project, at least 1;
    /// always 1 for other build systems, whose test runs share an `.xctestrun` file and DerivedData.
    var workerCount: Int {
        guard buildSystem == .swift else { return 1 }
        return max(1, mutationTestWorkers ?? 1)
    }

    /// This configuration with `testSuiteTimeout` set to `timeout`, unless it already has one.
    func withDefaultTestSuiteTimeout(_ timeout: TimeInterval) -> MuterConfiguration {
        guard testSuiteTimeout == nil else { return self }
        return MuterConfiguration(
            executable: testCommandExecutable,
            arguments: testCommandArguments,
            excludeList: excludeFileList,
            excludeCallList: excludeCallList,
            coverageThreshold: coverageThreshold,
            testSuiteTimeOut: timeout,
            mutationTestWorkers: mutationTestWorkers,
            buildSystem: explicitBuildSystem
        )
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
    /// A copy of this configuration whose test command runs `executable`.
    func withExecutable(_ executable: String) -> MuterConfiguration {
        MuterConfiguration(
            executable: executable,
            arguments: testCommandArguments,
            excludeList: excludeFileList,
            excludeCallList: excludeCallList,
            coverageThreshold: coverageThreshold,
            testSuiteTimeOut: testSuiteTimeout,
            mutationTestWorkers: mutationTestWorkers,
            buildSystem: explicitBuildSystem
        )
    }
}

extension MuterConfiguration {
    static let fileName = "muter.conf"
    static let `extension` = "yml"
    static let fileNameWithExtension = "\(fileName).\(`extension`)"
    static let legacyFileNameWithExtension = "\(fileName).json"
}

extension MuterConfiguration {
    var asData: Data {
        let encoder = YAMLEncoder()
        return (try! encoder.encode(self)).data(using: .utf8)!
    }
}

extension MuterConfiguration {
    var enableCoverageArguments: [String] {
        let arguments = testCommandArguments

        switch buildSystem {
        case .xcodebuild:
            // Xcode prints no build settings, such as BUILD_DIR, for a Swift package, so for a package
            // Muter chooses the build folder itself. Projects and workspaces keep their own build
            // location (for example SYMROOT in an .xcconfig), which -derivedDataPath would not override.
            let arguments = testsSwiftPackageWithXcodebuild ? argumentsWithDerivedDataPath : arguments
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
            return testArgumentsWithtDerivedData() + ["clean", "build-for-testing"]
        case .swift,
             .unknown:
            return arguments
        }
    }

    var derivedDataPath: String {
        guard let index = derivedDataArgumentIndex() else {
            return defaultDerivedData
        }

        return testCommandArguments[index + 1]
    }
    
    private var defaultDerivedData: String { "DerivedData" }

    func testWithoutBuildArguments(with testRunFile: String) -> [String] {
        let arguments = testCommandArguments
        switch buildSystem {
        case .xcodebuild:
            guard let destinationIndex = indexOfArgument("-destination") else {
                return arguments
            }
            return [
                "test-without-building",
                testCommandArguments[destinationIndex],
                testCommandArguments[destinationIndex + 1],
                "-xctestrun",
                testRunFile
            ]
        case .swift:
            return arguments + ["--skip-build"]
        case .unknown:
            return arguments
        }
    }

    private func indexOfArgument(_ arg: String) -> Int? {
        testCommandArguments.firstIndex(of: arg)
    }

    private func derivedDataArgumentIndex() -> Int? {
        indexOfArgument("-derivedDataPath")
    }

    /// An xcodebuild command without `-project` or `-workspace` runs on the Swift package in the
    /// current folder.
    var testsSwiftPackageWithXcodebuild: Bool {
        buildSystem == .xcodebuild
            && indexOfArgument("-project") == nil
            && indexOfArgument("-workspace") == nil
    }

    /// The test command with `-derivedDataPath`, added only when the user did not set one.
    var argumentsWithDerivedDataPath: [String] {
        derivedDataArgumentIndex() == nil
            ? testCommandArguments + ["-derivedDataPath", defaultDerivedData]
            : testCommandArguments
    }

    private func testArgumentsWithtDerivedData() -> [String] {
        guard derivedDataArgumentIndex() == nil else {
            return testCommandArguments
        }
        
        guard let testArgsIndex = indexOfArgument("test") else {
            return testCommandArguments
        }
        
        var args = testCommandArguments
        args.remove(at: testArgsIndex)
        args.append("-derivedDataPath")
        args.append(defaultDerivedData)
        
        return args
    }
}
