@testable import muterCore
import SwiftSyntax
import Quick
import Nimble

class DiscoverMutationPointSpec: QuickSpec {
    override func spec() {
        describe("the MutationPointDiscovery step") {
            context("when it discovers where mutants can be inserted into a Swift file") {
                
                var state: RunCommandState!
                var result: Result<[RunCommandState.Change], MuterError>!
                
                beforeEach {
                    state = RunCommandState()
                    state.sourceFileCandidates = [
                        "\(self.fixturesDirectory)/sampleForDiscoveringMutations.swift",
                        "\(self.fixturesDirectory)/sample With Spaces For Discovering Mutations.swift",
                    ]

                    result = DiscoverMutationPoints().run(with: state)
                }
                
                it("returns state changes which can add mutation points and the parsed source code") {
                    let filePath1 = "\(self.fixturesDirectory)/sampleForDiscoveringMutations.swift"
                    let filePath2 = "\(self.fixturesDirectory)/sample With Spaces For Discovering Mutations.swift"

                    guard case .success(let stateChanges) = result! else {
                        fail("expected success but got \(String(describing: result!))")
                        return
                    }

                    let stateChangesIncludesParsedSourceCode = stateChanges.contains {
                        let expectedFilePaths = Set([filePath2, filePath1])
                        let expectedSourceCode = Set([
                            sourceCode(fromFileAt: filePath1)!.code.description,
                            sourceCode(fromFileAt: filePath2)!.code.description,
                        ])

                        if case .sourceCodeParsed(let parsedSourceCode) = $0 {
                            let actualFilePaths = Set(parsedSourceCode.map { $0.key })
                            let actualSourceCode = Set(parsedSourceCode.map { $0.value.description })
                            return (expectedSourceCode, expectedFilePaths) == (actualSourceCode, actualFilePaths)
                        }
                        return false
                    }

                    let stateChangesIncludesMutationPoints = stateChanges.contains {
                        if case .mutationPointsDiscovered(let actualMutationPoints) = $0 {
                            return actualMutationPoints == [
                                MutationPoint(mutationOperatorId: .ror,
                                              filePath: filePath1,
                                              position: MutationPosition(utf8Offset: 84, line: 3, column: 19)),
                                MutationPoint(mutationOperatorId: .ror,
                                              filePath: filePath1,
                                              position: MutationPosition(utf8Offset: 106, line: 4, column: 18)),
                                MutationPoint(mutationOperatorId: .removeSideEffects,
                                              filePath: filePath2,
                                              position: MutationPosition(utf8Offset: 154, line: 6, column: 42)),
                                MutationPoint(mutationOperatorId: .removeSideEffects,
                                              filePath: filePath2,
                                              position: MutationPosition(utf8Offset: 177, line: 7, column: 23)),
                            ]
                        }
                        return false
                    }

                    expect(stateChangesIncludesParsedSourceCode) == true
                    expect(stateChangesIncludesMutationPoints) == true
                }

                context("if there are files which do not contain valid swift code") {
                    beforeEach {
                        state = RunCommandState()
                        state.sourceFileCandidates = [
                            "\(self.fixturesDirectory)/sampleForDiscoveringMutations.swift",
                            "\(self.fixturesDirectory)/muter.conf.json",
                        ]

                        result = DiscoverMutationPoints().run(with: state)
                    }
                }

                context("if there are lines marked for skipping") {
                    let samplePath = "\(self.fixturesDirectory)/sample with mutations marked for skipping.swift"
                    beforeEach {
                        state = RunCommandState()
                        state.sourceFileCandidates = [samplePath]

                        result = DiscoverMutationPoints().run(with: state)
                    }

                    it("skips candidate mutations on these lines") {
                        guard case .success(let stateChanges) = result! else {
                            fail("expected success but got \(String(describing: result!))")
                            return
                        }

                        let stateChangesIncludesOnlyUnskippedMutationPoints = stateChanges.contains {
                            if case .mutationPointsDiscovered(let actualMutationPoints) = $0 {
                                return actualMutationPoints == [
                                    MutationPoint(mutationOperatorId: .removeSideEffects,
                                                  filePath: samplePath,
                                                  position: MutationPosition(utf8Offset: 53, line: 3, column: 42)),
                                ]
                            }
                            return false
                        }

                        expect(stateChangesIncludesOnlyUnskippedMutationPoints) == true
                    }
                }

            }
            
            context("when it doesn't discover any mutants that can be inserted into a Swift file") {

                var result: Result<[RunCommandState.Change], MuterError>!
                var state: RunCommandState!

                context("because the code isn't mutable by the operators Muter implements") {
                    beforeEach {
                        state = RunCommandState()
                        state.sourceFileCandidates = [
                            "\(self.fixturesDirectory)/sourceWithoutMutableCode.swift",
                        ]

                        result = DiscoverMutationPoints().run(with: state)
                    }

                    it("cascades a failure up with a reason which explains why it couldn't discover any mutation points") {
                        guard case .failure(.noMutationPointsDiscovered) = result! else {
                            fail("expected a noMutationPointsDiscovered error but got \(String(describing: result!))")
                            return
                        }
                    }
                }
            }
        }
    }
}
