import Quick
import Nimble

import Foundation
import TestingExtensions
import SnapshotTesting
@testable import muterCore

@available(OSX 10.13, *)
class AcceptanceTests: QuickSpec {
    
    override func spec() {
        
        describe("someone using Muter for mutation testing", flags: [:]) {
            
            let messages = (
                mutationScoreOfTestSuite: "Mutation Score of Test Suite: 40%",
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
                        
                        beforeEach {
                            output = self.muterOutput
                        }
                        
                        they("see that their files are copied to a temp folder") {
                            expect(output.contains("Copying your project to a temporary directory for testing")).to(beTrue())
                        }
                        
                        they("see the list of files that Muter discovered") {
                            expect(output.contains("Discovered 3 Swift files")).to(beTrue())
                            expect(self.numberOfDiscoveredFileLists(in: output)).to(beGreaterThanOrEqualTo(1))
                        }
                        
                        they("see that Muter is working in a temporary directory") {
                            expect(output.contains("/var/folders")).to(beTrue())
                            expect(output.contains("/T/TemporaryItems/")).to(beTrue())
                        }
                        
                        they("see how many mutation operators it's able to perform") {
                            expect(output.contains("In total, Muter applied 5 mutation operators.")).to(beTrue())
                        }
                        
                        they("see the mutation scores for their test suite") {
                            expect(output.contains(messages.mutationScoresHeader)).to(beTrue())
                            expect(output.contains(messages.mutationScoreOfTestSuite)).to(beTrue())
                        }
                        
                        they("see which mutation operators were applied") {
                            expect(output.contains(messages.appliedMutationOperatorsHeader)).to(beTrue())
                        }
                    }
                }
                
                context("with --output-xcode as an argument") {
                    var output: String!
                    
                    beforeEach {
                        output = self.muterXcodeOutput
                    }
                    
                    they("see their results in a format consumable by an Xcode build script") {
                        expect(self.numberOfXcodeFormattedMessages(in: output)).to(equal(3))
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
                
                context("when a user's test suite doesn't pass an initial run", flags: [:]) {
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
            }
            
            context("with the 'init' command") {
                they("have a configuration file created for them") {
                    let decodedConfiguration = try? JSONDecoder().decode(MuterConfiguration.self, from: self.createdConfiguration)
                    expect(decodedConfiguration).toNot(beNil())
                }
            }
            
            context("with the 'help' command") {
                they("have the list of available commands displayed to them") {
                    expect(self.muterHelpOutput).to(contain("init"))
                    expect(self.muterHelpOutput).to(contain("help"))
                    expect(self.muterHelpOutput).to(contain("--output-json"))
                    expect(self.muterHelpOutput).to(contain("--output-xcode"))
                }
            }
        }
    }
}

@available(OSX 10.13, *)
extension AcceptanceTests {
    
    var rootTestDirectory: String {
        return String(
            URL(fileURLWithPath: #file)
                .deletingLastPathComponent()
                .withoutScheme()
        )
    }

    var muterOutputPath: String { return "\(AcceptanceTests().rootTestDirectory)/muters_output.txt" }
    var muterOutput: String {
        return contentsOfFileAsString(at: muterOutputPath)
    }
    
    var muterXcodeOutputPath: String { return "\(AcceptanceTests().rootTestDirectory)/muters_xcode_output.txt" }
    var muterXcodeOutput: String {
        return contentsOfFileAsString(at: muterXcodeOutputPath)
    }

    var muterEmptyStateOutputPath: String { return "\(AcceptanceTests().rootTestDirectory)/muters_empty_state_output.txt" }
    var muterEmptyStateOutput: String {
        return contentsOfFileAsString(at: muterEmptyStateOutputPath)
    }

    var muterAbortedTestingOutputPath: String { return "\(AcceptanceTests().rootTestDirectory)/muters_aborted_testing_output.txt" }
    var muterAbortedTestingOutput: String {
        return contentsOfFileAsString(at: muterAbortedTestingOutputPath)
    }
    
    var createdConfigurationPath: String { return "\(AcceptanceTests().rootTestDirectory)/created_config.json" }
    var createdConfiguration: Data {
        return contentsOfFileAsData(at: createdConfigurationPath)
    }
    
    var muterHelpOutputPath: String { return "\(AcceptanceTests().rootTestDirectory)/muters_help_output.txt" }
    var muterHelpOutput: String {
        return contentsOfFileAsString(at: muterHelpOutputPath)
    }

    func contentsOfFileAsString(at path: String) -> String {
        guard let data = FileManager.default.contents(atPath: path),
            let output = String(data: data, encoding: .utf8) else {
                fatalError("Unable to find a valid output file from a prior run of Muter at \(path)")
        }
        return output
    }
    
    func contentsOfFileAsData(at path: String) -> Data {
        guard let data = FileManager.default.contents(atPath: path) else {
                fatalError("Unable to find a valid output file from a prior run of Muter at \(path)")
        }
        return data
    }

    func numberOfDiscoveredFileLists(in output: String) -> Int {
        return applyRegex("Discovered \\d* Swift files:\n\n(/[^/ ]*)+/?", to: output)
    }
    
    func numberOfXcodeFormattedMessages(in output: String) -> Int {
        return applyRegex("[\\/[:alnum:]\\/]+[a-zA-Z]+.swift\\:[0-9]+:[0-9]+\\: warning: [a-zA-Z ]+: [a-zA-Z[:punct:] ]+/?",
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
