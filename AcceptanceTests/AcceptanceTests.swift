@testable import muterCore
import SnapshotTesting
import TestingExtensions
import XCTest

private enum AcceptanceTestsError: Error {
    case reason(String)
}

final class AcceptanceTests: XCTestCase {
    private let messages = (
        mutationScoreOfTestSuite: "Mutation Score of Test Suite: 33%",
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

    func test_runCommand() throws {
        let output = try muterOutput
        let logFiles = try muterLogFiles

        XCTAssertTrue(output.contains("Copying your project to a temporary directory for testing"))

        XCTAssertTrue(output.contains("In total, Muter discovered 4 Swift files"))
        XCTAssertTrue(try numberOfDiscoveredFileLists(in: output) >= 1)

        XCTAssertTrue(output.contains("_mutated"))

        XCTAssertTrue(output.contains("In total, Muter introduced 3 mutants in 3 files."))

        XCTAssertEqual(try numberOfProgressUpdates(in: output), 3)
        XCTAssertEqual(try numberOfDurationEstimates(in: output), 3)

        XCTAssertTrue(output.contains(messages.mutationScoresHeader))
        XCTAssertTrue(output.contains(messages.mutationScoreOfTestSuite))

        XCTAssertTrue(output.contains(messages.appliedMutationOperatorsHeader))

        let expectedLogFiles = [
            "baseline run.log",
            "ChangeLogicalConnector @ Module2.swift-2-17.log",
            "RelationalOperatorReplacement @ Module.swift-4-7.log",
            "RemoveSideEffects @ ViewController.swift-5-28.log"
        ]

        let numberOfEmptyLogFiles = try expectedLogFiles
            .map(contentsOfLogFile(named:))
            .count { $0.isEmpty }

        XCTAssertEqual(
            logFiles.sorted(),
            expectedLogFiles.sorted()
        ) // Sort these so it's easier to reason about any erroneous failures
        XCTAssertEqual(numberOfEmptyLogFiles, 0)
    }

    func test_runWithTestPlanCommand() throws {
        let output = try mutersOutputWithTestPlan

        XCTAssertTrue(output.contains("Muter mutation test plan loaded"))
    }

    func test_withCoverage() throws {
        let output = try muterWithCoverageOutput

        XCTAssertTrue(output.contains("Code Coverage of your project:"))
    }

    func test_xcodeFormat() throws {
        let output = try muterXcodeOutput

        XCTAssertEqual(try numberOfXcodeFormattedMessages(in: output), 1)
    }

    func test_filesToMutate() throws {
        let output = try muterFilesToMutateOutput

        XCTAssertTrue(output.contains("In total, Muter discovered 1 mutants in 1 files"))
    }

    func test_muterDoesntDiscoverAnyMutationOperators() throws {
        let output = try muterEmptyStateOutput

        XCTAssertTrue(output.contains("Muter wasn't able to discover any code it could mutation test."))
        XCTAssertFalse(output.contains(messages.mutationScoresHeader))
        XCTAssertFalse(output.contains(messages.mutationScoreOfTestSuite))
        XCTAssertFalse(output.contains(messages.appliedMutationOperatorsHeader))
    }

    func test_initCommandOniOSProject() throws {
        let decodedConfiguration = try MuterConfiguration(from: createdIOSConfiguration)
        XCTAssertEqual(decodedConfiguration.testCommandExecutable, "/usr/bin/xcodebuild")
        XCTAssertTrue(decodedConfiguration.testCommandArguments.contains("-destination"))
        XCTAssertTrue(
            decodedConfiguration.testCommandArguments
                .contains { $0.contains("platform=iOS Simulator,name=iPhone") }
        )
    }

    func test_initCommandOnMacOSProject() throws {
        let decodedConfiguration = try MuterConfiguration(from: createdMacOSConfiguration)
        XCTAssertEqual(decodedConfiguration.testCommandExecutable, "/usr/bin/xcodebuild")
        XCTAssertTrue(decodedConfiguration.testCommandArguments.contains("-destination"))
        XCTAssertTrue(
            decodedConfiguration.testCommandArguments.contains { $0.contains("platform=macOS,arch=arm64") }
        )
    }

    func test_mutationTestPlan() throws {
        let decodedTestPlan = try JSONDecoder().decode(MuterTestPlan.self, from: createdTestPlan)
        XCTAssertTrue(decodedTestPlan.mutatedProjectPath.contains("_mutated"))
        XCTAssertEqual(decodedTestPlan.projectCoverage, 23)
        XCTAssertEqual(decodedTestPlan.mappings.count, 1)
    }

    func test_mutationTestTimeout() throws {
        let output = try muterWithTimeoutOutput

        XCTAssertTrue(output.contains("""
        File                         Applied Mutation Operator       Mutation Test Result
        ----                         -------------------------       --------------------
        ProjectWithTimeout.swift:2   RelationalOperatorReplacement   time out
        """))
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

    var muterOutput: String {
        get throws {
            try contentsOfFileAsString("\(rootTestDirectory)/samples/muters_output.txt")
        }
    }

    var mutersOutputWithTestPlan: String {
        get throws {
            try contentsOfFileAsString("\(rootTestDirectory)/samples/muters_output_with_test_plan.txt")
        }
    }

    var muterXcodeOutput: String {
        get throws {
            try contentsOfFileAsString("\(rootTestDirectory)/samples/muters_xcode_output.txt")
        }
    }

    var muterFilesToMutateOutput: String {
        get throws {
            try contentsOfFileAsString(
                "\(rootTestDirectory)/samples/muters_files_to_mutate_output.txt"
            )
        }
    }

    var muterWithCoverageOutput: String {
        get throws {
            try contentsOfFileAsString("\(rootTestDirectory)/samples/muters_with_coverage_output.txt")
        }
    }
    
    var muterWithTimeoutOutput: String {
        get throws {
            try contentsOfFileAsString("\(rootTestDirectory)/samples/muters_timeout_output.txt")
        }
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

    var muterLogFiles: [String] {
        get throws {
            try contentsOfDirectory(muterLogsRootPath)
                .map { muterLogsRootPath + "/" + $0 }
                .flatMap(contentsOfDirectory)
        }
    }

    var createdIOSConfiguration: Data {
        get throws {
            try contentsOfFileAsData("\(rootTestDirectory)/samples/created_iOS_config.yml")
        }
    }

    var createdMacOSConfiguration: Data {
        get throws {
            try contentsOfFileAsData("\(rootTestDirectory)/samples/created_macOS_config.yml")
        }
    }

    var createdTestPlan: Data {
        get throws {
            try contentsOfFileAsData("\(rootTestDirectory)/samples/created_muter-mappings.json")
        }
    }

    var muterLogsRootPath: String { "\(rootTestDirectory)/samples/muter_logs/" }
}

extension AcceptanceTests {
    func contentsOfLogFile(named fileName: String) throws -> String {
        try contentsOfDirectory(muterLogsRootPath)
            .first
            .map { muterLogsRootPath + $0 + "/" + fileName }
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
