import Nimble
import Quick

import Foundation
import TestingExtensions

@testable import muterCore

final class AcceptanceTests: QuickSpec {
    override func spec() {
        describe("someone using Muter for mutation testing") {
            let messages = (
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
            
            context("with the 'run' command") {
                context("without any arguments") {
                    context("when Muter discovers operators it can apply") {
                        var output: String!
                        var logFiles: [String]!
                        
                        beforeEach {
                            output = self.muterOutput
                            logFiles = self.muterLogFiles
                        }
                        
                        they("see that their files are copied to a temp folder") {
                            expect(output.contains("Copying your project to a temporary directory for testing")).to(beTrue())
                        }
                        
                        they("see the list of files that Muter discovered") {
                            expect(output.contains("In total, Muter discovered 4 Swift files")).to(beTrue())
                            expect(self.numberOfDiscoveredFileLists(in: output)).to(beGreaterThanOrEqualTo(1))
                        }
                        
                        they("see that Muter is working in a temporary directory") {
                            expect(output.contains("/var/folders")).to(beTrue())
                            expect(output.contains("/T/TemporaryItems/")).to(beTrue())
                        }
                        
                        they("see how many mutants were inserted") {
                            expect(output.contains("In total, Muter introduced 3 mutants in 3 files.")).to(beTrue())
                        }
                        
                        they("see an estimated time til completion with progress updates") {
                            expect(self.numberOfProgressUpdates(in: output)) == 4
                            expect(self.numberOfDurationEstimates(in: output)) == 4
                        }
                        
                        they("see the mutation scores for their test suite") {
                            expect(output.contains(messages.mutationScoresHeader)).to(beTrue())
                            expect(output.contains(messages.mutationScoreOfTestSuite)).to(beTrue())
                        }
                        
                        they("see which mutation operators were applied") {
                            expect(output.contains(messages.appliedMutationOperatorsHeader)).to(beTrue())
                        }
                        
                        they("see the logs from their test runner copied into their project's directory") {
                            let expectedLogFiles = [
                                "baseline run.log",
                                "ChangeLogicalConnector @ Module2.swift-2-17.log",
                                "RelationalOperatorReplacement @ Module.swift-4-18.log",
                                "RemoveSideEffects @ ViewController.swift-5-28.log",
                            ]
                            
                            let numberOfEmptyLogFiles = expectedLogFiles
                                .map(self.contentsOfLogFile(named:))
                                .count { $0.isEmpty }
                            
                            expect(logFiles.sorted()).to(equal(expectedLogFiles.sorted())) // Sort these so it's easier to reason about any erroneous failures
                            expect(numberOfEmptyLogFiles) == 0
                        }
                    }
                }
                
                context("without '--skip-coverage' as an argument") {
                    var output: String!
                    
                    beforeEach {
                        output = self.muterWithCoverageOutput
                    }
                    
                    they("see their project code coverage") {
                        expect(output.contains("Code Coverage of your project: ")).to(beTrue())
                    }
                }
                
                context("with '--format xcode' as an argument") {
                    var output: String!
                    
                    beforeEach {
                        output = self.muterXcodeOutput
                    }
                    
                    they("see their results in a format consumable by an Xcode build script") {
                        expect(self.numberOfXcodeFormattedMessages(in: output)).to(equal(1))
                    }
                    
                    they("see only one temporary path") {
                        let numberOfTemporaryPaths = output.split(separator: "\n").count {
                            $0.contains("/T/TemporaryItems/")
                        }
                        expect(numberOfTemporaryPaths) == 1
                    }
                }
                
                context("with '--files-to-mutate' as an argument") {
                    var output: String!
                    
                    beforeEach {
                        output = self.muterFilesToMutateOutput
                    }
                    
                    they("only mutate the given list") {
                        expect(output.contains("In total, Muter discovered 1 mutants in 1 files")).to(beTrue())
                    }
                }
                
                context("when Muter doesn't discover any mutation operators") {
                    var output: String!
                    
                    beforeEach {
                        output = self.muterEmptyStateOutput
                    }
                    
                    they("see a message that explains Muter wasn't able to discover any code for testing") {
                        expect(output.contains("Muter wasn't able to discover any code it could mutation test.")).to(beTrue())
                    }
                    
                    they("see no mutation scores") {
                        expect(output.contains(messages.mutationScoresHeader)).to(beFalse())
                        expect(output.contains(messages.mutationScoreOfTestSuite)).to(beFalse())
                    }
                    
                    they("don't see a list of mutation operators that were applied") {
                        expect(output.contains(messages.appliedMutationOperatorsHeader)).to(beFalse())
                    }
                }
                
                context("when a user's test suite doesn't pass an initial run") {
                    var output: String!
                    
                    beforeEach {
                        output = self.muterAbortedTestingOutput
                    }
                    
                    they("see that Muter wasn't able to mutation test their project because of an issue with their test suite") {
                        expect(output.contains("Muter noticed that your test suite initially failed to compile or produced a test failure.")).to(beTrue())
                    }
                    
                    they("see no mutation scores") {
                        expect(output.contains(messages.mutationScoresHeader)).to(beFalse())
                        expect(output.contains(messages.mutationScoreOfTestSuite)).to(beFalse())
                    }
                    
                    they("don't see a list of mutation operators that were applied") {
                        expect(output.contains(messages.appliedMutationOperatorsHeader)).to(beFalse())
                    }
                }
                
                context("see that Muter is working in a sibling directory") {
                    var output: String!
                    
                    beforeEach {
                        output = self.muterWithMutateInSiblingFolderOutput
                    }
                    
                    they("see sibling project folder path") {
                        let numberOfPaths = output.split(separator: "\n").count {
                            $0.contains("_mutated")
                        }
                        expect(numberOfPaths) == 1
                    }
                }
            }
            
            
            context("with the 'init' command") {
                context("ran inside of a directory containing an iOS project") {
                    they("have a configuration file created for them") {
                        let decodedConfiguration = try? MuterConfiguration(from: self.createdIOSConfiguration)
                        expect(decodedConfiguration?.testCommandExecutable) == "/usr/bin/xcodebuild"
                        expect(decodedConfiguration?.testCommandArguments).to(contain("-destination"))
                        expect(decodedConfiguration?.testCommandArguments).to(contain("platform=iOS Simulator,name=iPhone 8"))
                        expect(decodedConfiguration?.mutateFilesInSiblingOfProjectFolder) == false
                    }
                }
                
                context("ran inside of a directory containing a macOS project") {
                    they("have a configuration file created for them") {
                        let decodedConfiguration: MuterConfiguration? = try? MuterConfiguration(from: self.createdMacOSConfiguration)
                        expect(decodedConfiguration?.testCommandExecutable) == "/usr/bin/xcodebuild"
                        expect(decodedConfiguration?.testCommandArguments).toNot(contain("-destination"))
                        expect(decodedConfiguration?.testCommandArguments).toNot(contain("platform=iOS Simulator,name=iPhone 8"))
                        expect(decodedConfiguration?.mutateFilesInSiblingOfProjectFolder) == false
                    }
                }
            }
            
            context("with the 'help' command") {
                they("have the list of available commands displayed to them") {
                    expect(self.muterHelpOutput).to(
                        equalWithDiff(
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
                    )
                }
                
                when("'init' is the subcommand") {
                    they("have the description displayed to them") {
                        expect(self.muterInitHelpOutput).to(
                            equalWithDiff(
                                """
                                OVERVIEW: Creates the configuration file that Muter uses
                                
                                USAGE: muter init
                                
                                OPTIONS:
                                  --version               Show the version.
                                  -h, --help              Show help information.
                                
                                
                                """
                            )
                        )
                    }
                }
                
                when("'run' is the subcommand") {
                    they("have the description displayed to them") {
                        expect(self.muterRunHelpOutput).to(
                            equalWithDiff(
                                """
                                OVERVIEW: Performs mutation testing for the Swift project contained within the
                                current directory.

                                USAGE: muter run [--files-to-mutate <files-to-mutate> ...] [--format <format>] [--skip-coverage] [--output <output>]

                                OPTIONS:
                                  --files-to-mutate <files-to-mutate>
                                                          Only mutate a given list of source code files.
                                  -f, --format <format>   The report format for muter: plain, json, html, xcode
                                                          (default: plain)
                                  --skip-coverage         Skips the step in which Muter runs your project in
                                                          order to filter out files without coverage.
                                  -o, --output <output>   Output file for the report to be saved.
                                  --version               Show the version.
                                  -h, --help              Show help information.


                                """
                            )
                        )
                    }
                }
            }
        }
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
