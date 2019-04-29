@testable import muterCore
import SwiftSyntax
import Quick
import Nimble

class MutationOperatorDiscoverySpec: QuickSpec {
    override func spec() {
        describe("discoverMutationOperators") {
            it("discovers the mutation operators that can be applied to a Swift file") {
                let operators = discoverMutationOperators(inFilesAt: [
                    "\(self.fixturesDirectory)/sampleForDiscoveringMutations.swift",
                    "\(self.fixturesDirectory)/sample With Spaces For Discovering Mutations.swift"
                ])

                guard operators.count == 4 else {
                    fail("Expected to find 4 mutation operators, but got \(operators.count) instead")
                    return
                }

                expect(operators[0].filePath).to(equal("\(self.fixturesDirectory)/sampleForDiscoveringMutations.swift"))
                expect(operators[1].filePath).to(equal("\(self.fixturesDirectory)/sampleForDiscoveringMutations.swift"))
                expect(operators[2].filePath).to(equal("\(self.fixturesDirectory)/sample With Spaces For Discovering Mutations.swift"))
                expect(operators[3].filePath).to(equal("\(self.fixturesDirectory)/sample With Spaces For Discovering Mutations.swift"))

                expect(operators[0].position.line).to(equal(3))
                expect(operators[1].position.line).to(equal(4))
                expect(operators[2].position.line).to(equal(6))
                expect(operators[3].position.line).to(equal(7))
            }

            it("doesn't discover any mutation operators when the Swift code isn't mutable by the operators Muter implements") {
                let operators = discoverMutationOperators(inFilesAt: ["\(self.fixturesDirectory)/sourceWithoutMuteableCode.swift"])
                expect(operators.count).to(equal(0))
            }

            it("doesn't discover any mutation operators in files that don't contain Swift code") {
                let operators = discoverMutationOperators(inFilesAt: [
                    "\(self.fixturesDirectory)/sampleForDiscoveringMutations.swift",
                    "\(self.fixturesDirectory)/muter.conf.json",
                ])

                let operatorsForNonSwiftCode = operators.exclude { $0.filePath.contains(".swift") }

                expect(operatorsForNonSwiftCode.count).to(equal(0))
                expect(operators.count).to(equal(2))
            }
        }
    }
}
