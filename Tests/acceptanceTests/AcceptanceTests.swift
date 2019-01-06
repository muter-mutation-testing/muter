@testable import muterCore
import testingCore
import SwiftSyntax
import Foundation
import Quick
import Nimble

@available(OSX 10.13, *)
class AcceptanceTests: QuickSpec {
    override func spec() {
        var originalSourceCode: SourceFileSyntax!
        var sourceCodePath: String!
        var output: String!

        beforeSuite {
            sourceCodePath = "\(self.exampleAppDirectory)/ExampleApp/Module.swift"
            originalSourceCode = sourceCode(fromFileAt: sourceCodePath)!

            output = self.muterOutput
        }

        describe("someone using Muter") {
            they("see the list of files that Muter discovered") {
                expect(output).to(contain("Discovered 3 Swift files"))
                expect(self.numberOfDiscoveredFileLists(in: output)).to(equal(1))
            }

            they("see how many mutations it's able to perform") {
                expect(output).to(contain("In total, Muter applied 9 mutation operators."))
            }

            they("see which runs of a mutation test passed and failed") {
                expect(output).to(contain("Mutation Test Passed"))
                expect(output).to(contain("Mutation Test Failed"))
            }

            they("see the mutation scores for their test suite") {
                let mutationScoresHeader = """
                --------------------
                Mutation Test Scores
                --------------------
                """

                expect(output).to(contain(mutationScoresHeader))
                expect(output).to(contain("Mutation Score of Test Suite (higher is better): 22/100"))
            }

            they("see which mutation operators were applied") {
                let appliedMutationOperatorsHeader = """
                --------------------------
                Applied Mutation Operators
                --------------------------
                """

                expect(output).to(contain(appliedMutationOperatorsHeader))
            }

            they("know that Muter cleans up after itself") {
                let afterSourceCode = sourceCode(fromFileAt: sourceCodePath)
                let workingDirectoryExists = FileManager.default.fileExists(atPath: "\(self.exampleAppDirectory)/muter_tmp", isDirectory: nil)

                expect(afterSourceCode).toNot(beNil())
                expect(originalSourceCode!.description).to(equal(afterSourceCode!.description))
                expect(workingDirectoryExists).to(beFalse())
            }
        }
    }
}

@available(OSX 10.13, *)
private extension AcceptanceTests {
    var exampleAppDirectory: String {
        return AcceptanceTests().productsDirectory
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent() // Go up 3 directories
            .appendingPathComponent("ExampleApp") // Go down 1 directory
            .withoutScheme() // Remove the file reference scheme
            .absoluteString
    }

    var muterOutputPath: String { return "\(AcceptanceTests().rootTestDirectory)/acceptanceTests/muters_output.txt" }

    var muterOutput: String {
        guard let data = FileManager.default.contents(atPath: muterOutputPath),
            let output = String(data: data, encoding: .utf8) else {
                fatalError("Unable to find a valid output file from a prior run of Muter at \(muterOutputPath)")
        }

        return output
    }

    func numberOfDiscoveredFileLists(in output: String) -> Int {
        let filePathRegex = try! NSRegularExpression(pattern: "Discovered \\d* Swift files:\n\n(/[^/ ]*)+/?", options: .anchorsMatchLines)
        let entireString = NSRange(location: 0, length: output.count)
        return filePathRegex.numberOfMatches(in: output,
                                             options: .withoutAnchoringBounds,
                                             range: entireString)
    }
}
