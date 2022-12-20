import XCTest
import TestingExtensions

@testable import muterCore

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
    
    func test_runCommand() {
        let output = muterOutput
        let logFiles = muterLogFiles
        
        XCTAssertTrue(output.contains("Copying your project to a temporary directory for testing"))
        
        XCTAssertTrue(output.contains("In total, Muter discovered 4 Swift files"))
        XCTAssertTrue(numberOfDiscoveredFileLists(in: output) >= 1)
        
        XCTAssertTrue(output.contains("/var/folders"))
        XCTAssertTrue(output.contains("/T/TemporaryItems/"))
        
        XCTAssertTrue(output.contains("In total, Muter introduced 3 mutants in 3 files."))
        
        XCTAssertEqual(self.numberOfProgressUpdates(in: output), 4)
        XCTAssertEqual(self.numberOfDurationEstimates(in: output), 4)
        
        XCTAssertTrue(output.contains(messages.mutationScoresHeader))
        XCTAssertTrue(output.contains(messages.mutationScoreOfTestSuite))
        
        XCTAssertTrue(output.contains(messages.appliedMutationOperatorsHeader))
        
        let expectedLogFiles = [
            "baseline run.log",
            "ChangeLogicalConnector @ Module2.swift-2-17.log",
            "RelationalOperatorReplacement @ Module.swift-4-18.log",
            "RemoveSideEffects @ ViewController.swift-5-28.log",
        ]
        
        let numberOfEmptyLogFiles = expectedLogFiles
            .map(self.contentsOfLogFile(named:))
            .count { $0.isEmpty }
        
        XCTAssertEqual(logFiles.sorted(), expectedLogFiles.sorted()) // Sort these so it's easier to reason about any erroneous failures
        XCTAssertEqual(numberOfEmptyLogFiles, 0)
    }
    
    func test_skipCoverage() {
        let output = muterWithCoverageOutput
        
        XCTAssertTrue(output.contains("Code Coverage of your project: "))
    }
    
    func test_xcodeFormat() {
        let output = muterXcodeOutput
        
        XCTAssertEqual(numberOfXcodeFormattedMessages(in: output), 1)
        
        let numberOfTemporaryPaths = output.split(separator: "\n").count {
            $0.contains("/T/TemporaryItems/")
        }
        XCTAssertEqual(numberOfTemporaryPaths, 1)
    }
    
    func test_filesToMutate() {
        let output = muterFilesToMutateOutput
        
        XCTAssertTrue(output.contains("In total, Muter discovered 1 mutants in 1 files"))
    }
    
    func test_muterDoesntDiscoverAnyMutationOperators() {
        let output = muterEmptyStateOutput
        
        XCTAssertTrue(output.contains("Muter wasn't able to discover any code it could mutation test."))
        XCTAssertFalse(output.contains(messages.mutationScoresHeader))
        XCTAssertFalse(output.contains(messages.mutationScoreOfTestSuite))
        XCTAssertFalse(output.contains(messages.appliedMutationOperatorsHeader))
    }
    
    func test_sibilingDirectory() {
        let output = muterWithMutateInSiblingFolderOutput
        
        let numberOfPaths = output.split(separator: "\n").count {
            $0.contains("_mutated")
        }
        XCTAssertEqual(numberOfPaths, 1)
    }
    
    func test_initCommandOniOSProject() {
        let decodedConfiguration = try? MuterConfiguration(from: self.createdIOSConfiguration)
        XCTAssertEqual(decodedConfiguration?.testCommandExecutable, "/usr/bin/xcodebuild")
        XCTAssertTrue(decodedConfiguration?.testCommandArguments.contains("-destination"))
        XCTAssertTrue(decodedConfiguration?.testCommandArguments.contains("platform=iOS Simulator,name=iPhone SE (3rd generation)"))
        XCTAssertFalse(decodedConfiguration?.mutateFilesInSiblingOfProjectFolder)
    }
    
    func test_initCommandOnMacOSProject() {
        let decodedConfiguration: MuterConfiguration? = try? MuterConfiguration(from: self.createdMacOSConfiguration)
        XCTAssertEqual(decodedConfiguration?.testCommandExecutable, "/usr/bin/xcodebuild")
        XCTAssertFalse(decodedConfiguration?.testCommandArguments.contains("-destination"))
        XCTAssertFalse(decodedConfiguration?.testCommandArguments.contains("platform=iOS Simulator,name=iPhone SE (3rd generation)"))
        XCTAssertFalse(decodedConfiguration?.mutateFilesInSiblingOfProjectFolder)
    }
    
    func test_helpCommand() {
        XCTAssertEqual(muterHelpOutput,
                """
                OVERVIEW: 🔎 Automated mutation testing for Swift 🕳️
                
                USAGE: muter <subcommand>
                
                OPTIONS:
                  --version               Show the version.
                  -h, --help              Show help information.
                
                SUBCOMMANDS:
                  init                    Creates the configuration file that Muter uses
                  run (default)           Performs mutation testing for the Swift project
                                          contained within the current directory.
                
                  See 'muter help <subcommand>' for detailed help.
                
                """
        )
    }
    
    func test_helpCommandInit() {
        XCTAssertEqual(muterInitHelpOutput,
                """
                OVERVIEW: Creates the configuration file that Muter uses
                
                USAGE: muter init
                
                OPTIONS:
                  --version               Show the version.
                  -h, --help              Show help information.
                
                
                """
        )
    }
    
    func test_helpCommandRun() {
        XCTAssertEqual(muterRunHelpOutput,
                """
                OVERVIEW: Performs mutation testing for the Swift project contained within the
                current directory.
                
                USAGE: muter run [--files-to-mutate <files-to-mutate> ...] [--format <format>] [--skip-coverage] [--output <output>]
                
                OPTIONS:
                  --files-to-mutate <files-to-mutate>
                                          Only mutate a given list of source code files.
                  -f, --format <format>   The report format for muter: plain, json, html, xcode
                  --skip-coverage         Skips the step in which Muter runs your project in
                                          order to filter out files without coverage.
                  -o, --output <output>   Output file for the report to be saved.
                  --version               Show the version.
                  -h, --help              Show help information.
                
                
                """
        )
    }
}

extension AcceptanceTests {
    var rootTestDirectory: String {
        return String(
            URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .withoutScheme()
        )
    }
    
    var muterOutput: String { contentsOfFileAsString("\(AcceptanceTests().rootTestDirectory)/samples/muters_output.txt") }
    var muterXcodeOutput: String { contentsOfFileAsString("\(AcceptanceTests().rootTestDirectory)/samples/muters_xcode_output.txt") }
    
    var muterFilesToMutateOutput: String { contentsOfFileAsString("\(AcceptanceTests().rootTestDirectory)/samples/muters_files_to_mutate_output.txt") }
    var muterWithCoverageOutput: String { contentsOfFileAsString("\(AcceptanceTests().rootTestDirectory)/samples/muters_with_coverage_output.txt") }
    
    var muterEmptyStateOutput: String { contentsOfFileAsString("\(AcceptanceTests().rootTestDirectory)/samples/muters_empty_state_output.txt") }
    var muterAbortedTestingOutput: String { contentsOfFileAsString("\(AcceptanceTests().rootTestDirectory)/samples/muters_aborted_testing_output.txt") }
    
    var muterWithMutateInSiblingFolderOutput: String { contentsOfFileAsString("\(AcceptanceTests().rootTestDirectory)/samples/muter_with_mutateInSiblingFolder_output.txt") }
    
    var muterHelpOutput: String { contentsOfFileAsString("\(AcceptanceTests().rootTestDirectory)/samples/muters_help_output.txt") }
    var muterInitHelpOutput: String { contentsOfFileAsString("\(AcceptanceTests().rootTestDirectory)/samples/muters_init_help_output.txt") }
    var muterRunHelpOutput: String { contentsOfFileAsString("\(AcceptanceTests().rootTestDirectory)/samples/muters_run_help_output.txt") }
    
    var muterLogFiles: [String] {
        contentsOfDirectory(muterLogsRootPath)
            .map { muterLogsRootPath + "/" + $0 }
            .flatMap(contentsOfDirectory)
    }
    
    var createdIOSConfiguration: Data { contentsOfFileAsData("\(AcceptanceTests().rootTestDirectory)/samples/created_iOS_config.yml") }
    var createdMacOSConfiguration: Data { contentsOfFileAsData("\(AcceptanceTests().rootTestDirectory)/samples/created_macOS_config.yml") }
    
    var muterLogsRootPath: String { "\(AcceptanceTests().rootTestDirectory)/samples/muter_logs/" }
}

extension AcceptanceTests {
    func contentsOfLogFile(named fileName: String) -> String {
        return contentsOfDirectory(muterLogsRootPath)
            .first
            .map { muterLogsRootPath + $0 + "/" + fileName }
            .map(contentsOfFileAsString)!
    }
    
    func contentsOfDirectory(_ path: String) -> [String] {
        return try! FileManager
            .default
            .contentsOfDirectory(atPath: path)
            .exclude { $0.starts(with: ".") } // this filters out hidden files/folders
    }
    
    func contentsOfFileAsString(_ path: String) -> String {
        guard let data = FileManager.default.contents(atPath: path),
              let output = String(data: data, encoding: .utf8)
        else {
            fatalError("File not found at \(path)")
        }
        return output
    }
    
    func contentsOfFileAsData(_ path: String) -> Data {
        guard let data = FileManager.default.contents(atPath: path) else {
            fatalError("Unable to find a valid output file from a prior run of Muter at \(path)")
        }
        return data
    }
}

extension AcceptanceTests {
    func numberOfDiscoveredFileLists(in output: String) -> Int {
        return applyRegex("[a-zA-Z]+.swift \\([0-9]+ mutants\\)", to: output)
    }
    
    func numberOfXcodeFormattedMessages(in output: String) -> Int {
        return applyRegex("[\\/[:alnum:]\\/]+[a-zA-Z]+.swift\\:[0-9]+:[0-9]+\\: warning: [a-zA-Z ]+: [a-zA-Z[:punct:] ]+/?",
                          to: output)
    }
    
    func numberOfProgressUpdates(in output: String) -> Int {
        return applyRegex("Percentage complete:  [0-9]+%/?",
                          to: output)
    }
    
    func numberOfDurationEstimates(in output: String) -> Int {
        return applyRegex("ETC: [0-9]+ minute/?",
                          to: output)
    }
    
    func applyRegex(_ regex: String, to output: String) -> Int {
        let filePathRegex = try! NSRegularExpression(pattern: regex, options: .anchorsMatchLines)
        let entireString = NSRange(location: 0, length: output.count)
        return filePathRegex.numberOfMatches(in: output,
                                             options: .withoutAnchoringBounds,
                                             range: entireString)
    }
}
