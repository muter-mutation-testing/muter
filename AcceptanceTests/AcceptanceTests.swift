@testable import muterCore
import SnapshotTesting
import TestingExtensions
import XCTest

private enum AcceptanceTestsError: Error {
    case reason(String)
}

final class AcceptanceTests: XCTestCase {
    enum Suffix: String {
        case xcodeproj
        case spm
    }

    private func messages(suffix: Suffix) -> (mutationScoreOfTestSuite: String, mutationScoresHeader: String, appliedMutationOperatorsHeader: String) {
        let percent = {
            switch suffix {
            case .xcodeproj: return "33"
            case .spm: return "33"
            }
        }()
        return (
            mutationScoreOfTestSuite: "Mutation Score of Test Suite: \(percent)%",
            mutationScoresHeader: """
            --------------------
            Mutation Test Scores
            --------------------
            """,
            appliedMutationOperatorsHeader: """
            --------------------------
            Applied Mutation Operators
            --------------------------
            """
        )
    }

    func test_runCommand_xcodeProj() throws {
        let output = try muterOutput(suffix: .xcodeproj)
        let logFiles = try muterLogFiles(suffix: .xcodeproj)

        XCTAssertTrue(output.contains("Copying your project to a temporary directory for testing"))

        XCTAssertTrue(output.contains("In total, Muter discovered 4 Swift files"))
        XCTAssertTrue(try numberOfDiscoveredFileLists(in: output) >= 1)

        XCTAssertTrue(output.contains("_mutated"))

        XCTAssertTrue(output.contains("In total, Muter introduced 3 mutants in 3 files."))

        XCTAssertEqual(try numberOfProgressUpdates(in: output), 3)
        XCTAssertEqual(try numberOfDurationEstimates(in: output), 3)

        XCTAssertTrue(output.contains(messages(suffix: .xcodeproj).mutationScoresHeader))
        XCTAssertTrue(output.contains(messages(suffix: .xcodeproj).mutationScoreOfTestSuite))

        XCTAssertTrue(output.contains(messages(suffix: .xcodeproj).appliedMutationOperatorsHeader))

        let expectedLogFiles = [
            "baseline run.log",
            "ChangeLogicalConnector @ Module2.swift-2-17.log",
            "RelationalOperatorReplacement @ Module.swift-4-7.log",
            "RemoveSideEffects @ ViewController.swift-5-28.log",
        ]

        let numberOfEmptyLogFiles = try expectedLogFiles
            .map { try contentsOfLogFile(named: $0, suffix: .xcodeproj) }
            .count { $0.isEmpty }

        XCTAssertEqual(
            logFiles.sorted(),
            expectedLogFiles.sorted()
        ) // Sort these so it's easier to reason about any erroneous failures
        XCTAssertEqual(numberOfEmptyLogFiles, 0)
    }

    func test_runWithTestPlanCommand_xcodeProj() throws {
        let output = try mutersOutputWithTestPlan(suffix: .xcodeproj)

        XCTAssertTrue(output.contains("Muter mutation test plan loaded"))
    }

    func test_withCoverage_xcodeProj() throws {
        let output = try muterWithCoverageOutput(suffix: .xcodeproj)

        XCTAssertTrue(output.contains("Code Coverage of your project:"))
    }

    func test_xcodeFormat_xcodeProj() throws {
        let output = try muterXcodeOutput(suffix: .xcodeproj)

        XCTAssertEqual(try numberOfXcodeFormattedMessages(in: output), 1)
    }

    func test_filesToMutate_xcodeProj() throws {
        let output = try muterFilesToMutateOutput(suffix: .xcodeproj)

        XCTAssertTrue(output.contains("In total, Muter discovered 1 mutants in 1 files"))
    }

    func test_runCommand_spm() throws {
        let output = try muterOutput(suffix: .spm)
        let logFiles = try muterLogFiles(suffix: .spm)

        XCTAssertTrue(output.contains("Copying your project to a temporary directory for testing"))

        XCTAssertTrue(output.contains("In total, Muter discovered 4 Swift files"))
        XCTAssertTrue(try numberOfDiscoveredFileLists(in: output) >= 1)

        XCTAssertTrue(output.contains("_mutated"))

        XCTAssertTrue(output.contains("In total, Muter introduced 3 mutants in 3 files."))

        XCTAssertEqual(try numberOfProgressUpdates(in: output), 3)
        XCTAssertEqual(try numberOfDurationEstimates(in: output), 3)

        XCTAssertTrue(output.contains(messages(suffix: .spm).mutationScoresHeader))
        XCTAssertTrue(output.contains(messages(suffix: .spm).mutationScoreOfTestSuite))

        XCTAssertTrue(output.contains(messages(suffix: .spm).appliedMutationOperatorsHeader))

        let expectedLogFiles = [
            "baseline run.log",
            "ChangeLogicalConnector @ Module2.swift-2-17.log",
            "RelationalOperatorReplacement @ Module.swift-4-7.log",
            "RemoveSideEffects @ ViewController.swift-5-28.log",
        ]

        let numberOfEmptyLogFiles = try expectedLogFiles
            .map { try contentsOfLogFile(named: $0, suffix: .spm) }
            .count { $0.isEmpty }

        XCTAssertEqual(
            logFiles.sorted(),
            expectedLogFiles.sorted()
        ) // Sort these so it's easier to reason about any erroneous failures
        XCTAssertEqual(numberOfEmptyLogFiles, 0)
    }

    func test_runWithTestPlanCommand_spm() throws {
        let output = try mutersOutputWithTestPlan(suffix: .spm)

        XCTAssertTrue(output.contains("Muter mutation test plan loaded"))
    }

    func test_withCoverage_spm() throws {
        let output = try muterWithCoverageOutput(suffix: .spm)

        XCTAssertTrue(output.contains("Code Coverage of your project:"))
    }

    func test_xcodeFormat_spm() throws {
        let output = try muterXcodeOutput(suffix: .spm)

        XCTAssertEqual(try numberOfXcodeFormattedMessages(in: output), 1)
    }

    func test_filesToMutate_spm() throws {
        let output = try muterFilesToMutateOutput(suffix: .spm)

        XCTAssertTrue(output.contains("In total, Muter discovered 1 mutants in 1 files"))
    }

    func test_muterDoesntDiscoverAnyMutationOperators() throws {
        let output = try muterEmptyStateOutput

        XCTAssertTrue(output.contains("Muter wasn't able to discover any code it could mutation test."))
        XCTAssertFalse(output.contains(messages(suffix: .xcodeproj).mutationScoresHeader))
        XCTAssertFalse(output.contains(messages(suffix: .xcodeproj).mutationScoreOfTestSuite))
        XCTAssertFalse(output.contains(messages(suffix: .xcodeproj).appliedMutationOperatorsHeader))
    }

    func test_initCommandOniOSProject_xcodeProj() throws {
        let decodedConfiguration = try MuterConfiguration(from: createdIOSConfiguration(suffix: .xcodeproj))
        XCTAssertEqual(decodedConfiguration.testCommandExecutable, "/usr/bin/xcodebuild")
        XCTAssertTrue(decodedConfiguration.testCommandArguments.contains("-destination"))
        XCTAssertTrue(
            decodedConfiguration.testCommandArguments
                .contains("platform=iOS Simulator,name=iPhone SE (3rd generation)")
        )
        XCTAssertEqual(decodedConfiguration.buildPath, ".build")
    }

    func test_initCommand_spm() throws {
        let decodedConfiguration = try MuterConfiguration(from: createdIOSConfiguration(suffix: .spm))
        XCTAssertEqual(decodedConfiguration.testCommandExecutable, "/usr/bin/xcodebuild")
        XCTAssertTrue(decodedConfiguration.testCommandArguments.contains("-scheme"))
        XCTAssertTrue(decodedConfiguration.testCommandArguments.contains("ExampleiOSPackage"))
        XCTAssertTrue(decodedConfiguration.testCommandArguments.contains("-destination"))
        XCTAssertTrue(
            decodedConfiguration.testCommandArguments
                .contains("platform=iOS Simulator,name=iPhone SE (3rd generation)")
        )
        XCTAssertEqual(decodedConfiguration.buildPath, ".build")
    }

    func test_initCommandOnMacOSProject_xcodeproj() throws {
        let decodedConfiguration = try MuterConfiguration(from: createdMacOSConfiguration(suffix: .xcodeproj))
        XCTAssertEqual(decodedConfiguration.testCommandExecutable, "/usr/bin/xcodebuild")
        XCTAssertFalse(decodedConfiguration.testCommandArguments.contains("-destination"))
        XCTAssertFalse(
            decodedConfiguration.testCommandArguments
                .contains("platform=iOS Simulator,name=iPhone SE (3rd generation)")
        )
        XCTAssertEqual(decodedConfiguration.buildPath, ".build")
    }

    func test_initCommandOnMacOSProject_spm() throws {
        let decodedConfiguration = try MuterConfiguration(from: createdMacOSConfiguration(suffix: .spm))
        XCTAssertEqual(decodedConfiguration.testCommandExecutable, "/usr/bin/swift")
        XCTAssertTrue(decodedConfiguration.testCommandArguments.contains("test"))
        XCTAssertEqual(decodedConfiguration.buildPath, ".build")
    }

    func test_mutationTestPlan_xcodeProj() throws {
        let decodedTestPlan = try JSONDecoder().decode(MuterTestPlan.self, from: createdTestPlan(suffix: .xcodeproj))
        XCTAssertTrue(decodedTestPlan.mutatedProjectPath.contains("_mutated"))
        XCTAssertEqual(decodedTestPlan.projectCoverage, 23)
        XCTAssertEqual(decodedTestPlan.mappings.count, 1)
    }

    func test_mutationTestPlan_spm() throws {
        let decodedTestPlan = try JSONDecoder().decode(MuterTestPlan.self, from: createdTestPlan(suffix: .spm))
        XCTAssertTrue(decodedTestPlan.mutatedProjectPath.contains("_mutated"))
        XCTAssertEqual(decodedTestPlan.projectCoverage, 23)
        XCTAssertEqual(decodedTestPlan.mappings.count, 1)
    }

    func test_all_operatos() throws {
        try AssertSnapshot(muterOperatorAllOutput)
    }

    func test_helpCommand() throws {
        try AssertSnapshot(muterHelpOutput)
    }

    func test_helpCommandInit() throws {
        try AssertSnapshot(muterInitHelpOutput)
    }

    func test_helpCommandRun() throws {
        try AssertSnapshot(muterRunHelpOutput)
    }

    func test_helpCommandOperator() throws {
        try AssertSnapshot(muterOperatorHelpOutput)
    }
}

extension AcceptanceTests {
    var rootTestDirectory: String {
        String(
            URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .withoutScheme()
        )
    }

    func muterOutput(suffix: Suffix) throws -> String {
        try contentsOfFileAsString("\(rootTestDirectory)/samples/muters_output.\(suffix).txt")
    }

    func mutersOutputWithTestPlan(suffix: Suffix) throws -> String {
        try contentsOfFileAsString("\(rootTestDirectory)/samples/muters_output_with_test_plan.\(suffix).txt")
    }

    func muterXcodeOutput(suffix: Suffix) throws -> String {
        try contentsOfFileAsString("\(rootTestDirectory)/samples/muters_xcode_output.\(suffix).txt")
    }

    func muterFilesToMutateOutput(suffix: Suffix) throws -> String {
        try contentsOfFileAsString(
            "\(rootTestDirectory)/samples/muters_files_to_mutate_output.\(suffix).txt"
        )
    }

    func muterWithCoverageOutput(suffix: Suffix) throws -> String {
        try contentsOfFileAsString("\(rootTestDirectory)/samples/muters_with_coverage_output.\(suffix).txt")
    }

    var muterEmptyStateOutput: String {
        get throws {
            try contentsOfFileAsString("\(rootTestDirectory)/samples/muters_empty_state_output.txt")
        }
    }

    var muterAbortedTestingOutput: String {
        get throws {
            try contentsOfFileAsString(
                "\(rootTestDirectory)/samples/muters_aborted_testing_output.txt"
            )
        }
    }

    var muterHelpOutput: String {
        get throws {
            try contentsOfFileAsString("\(rootTestDirectory)/samples/muters_help_output.txt")
        }
    }

    var muterInitHelpOutput: String {
        get throws {
            try contentsOfFileAsString("\(rootTestDirectory)/samples/muters_init_help_output.txt")
        }
    }

    var muterRunHelpOutput: String {
        get throws {
            try contentsOfFileAsString("\(rootTestDirectory)/samples/muters_run_help_output.txt")
        }
    }

    var muterOperatorHelpOutput: String {
        get throws {
            try contentsOfFileAsString("\(rootTestDirectory)/samples/muters_operator_help_output.txt")
        }
    }

    var muterOperatorAllOutput: String {
        get throws {
            try contentsOfFileAsString("\(rootTestDirectory)/samples/muters_operator_all_output.txt")
        }
    }

    func muterLogFiles(suffix: Suffix) throws -> [String] {
        try contentsOfDirectory(muterLogsRootPath(suffix: suffix))
            .map { muterLogsRootPath(suffix: suffix) + "/" + $0 }
            .flatMap(contentsOfDirectory)
    }

    func createdIOSConfiguration(suffix: Suffix) throws -> Data {
        try contentsOfFileAsData("\(rootTestDirectory)/samples/created_iOS_config.\(suffix).yml")
    }

    func createdMacOSConfiguration(suffix: Suffix) throws -> Data {
        try contentsOfFileAsData("\(rootTestDirectory)/samples/created_macOS_config.\(suffix).yml")
    }

    func createdTestPlan(suffix: Suffix) throws -> Data {
        try contentsOfFileAsData("\(rootTestDirectory)/samples/created_muter-mappings.\(suffix).json")
    }

    func muterLogsRootPath(suffix: Suffix) -> String {
        "\(rootTestDirectory)/samples/muter_logs_\(suffix)/"
    }
}

extension AcceptanceTests {
    func contentsOfLogFile(named fileName: String, suffix: Suffix) throws -> String {
        try contentsOfDirectory(muterLogsRootPath(suffix: suffix))
            .first
            .map { muterLogsRootPath(suffix: suffix) + $0 + "/" + fileName }
            .map(contentsOfFileAsString)!
    }

    func contentsOfDirectory(_ path: String) throws -> [String] {
        try FileManager
            .default
            .contentsOfDirectory(atPath: path)
            .exclude { $0.starts(with: ".") } // this filters out hidden files/folders
    }

    func contentsOfFileAsString(_ path: String) throws -> String {
        guard let data = FileManager.default.contents(atPath: path),
              let output = String(data: data, encoding: .utf8)
        else {
            throw AcceptanceTestsError.reason("File not found at \(path)")
        }

        return output
    }

    func contentsOfFileAsData(_ path: String) throws -> Data {
        guard let data = FileManager.default.contents(atPath: path) else {
            throw AcceptanceTestsError.reason("Unable to find a valid output file from a prior run of Muter at \(path)")
        }
        return data
    }
}

extension AcceptanceTests {
    func numberOfDiscoveredFileLists(in output: String) throws -> Int {
        try applyRegex("[a-zA-Z]+.swift \\([0-9]+ mutants\\)", to: output)
    }

    func numberOfXcodeFormattedMessages(in output: String) throws -> Int {
        try applyRegex(
            "[\\/[:alnum:]\\/]+[a-zA-Z]+.swift\\:[0-9]+:[0-9]+\\: warning: [a-zA-Z ]+: [a-zA-Z[:punct:] ]+/?",
            to: output
        )
    }

    func numberOfProgressUpdates(in output: String) throws -> Int {
        try applyRegex(
            "Percentage complete:  [0-9]+%/?",
            to: output
        )
    }

    func numberOfDurationEstimates(in output: String) throws -> Int {
        try applyRegex(
            "ETC: [0-9]+ minute/?",
            to: output
        )
    }

    func applyRegex(_ regex: String, to output: String) throws -> Int {
        let filePathRegex = try NSRegularExpression(pattern: regex, options: .anchorsMatchLines)
        let entireString = NSRange(location: 0, length: output.count)
        return filePathRegex.numberOfMatches(
            in: output,
            options: .withoutAnchoringBounds,
            range: entireString
        )
    }
}
