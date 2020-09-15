@testable import muterCore
import Foundation
import SwiftSyntax
import Quick
import Nimble

@available(OSX 10.13, *)
class PerformMutationTestingSpec: QuickSpec {
    override func spec() {
        
        var delegateSpy: MutationTestingDelegateSpy!
        var performMutationTesting: PerformMutationTesting!
        var state: RunCommandState!
        var result: Result<[RunCommandState.Change], MuterError>!
        let expectedMutationPoint = MutationPoint(mutationOperatorId: .ror,
                                                  filePath: "/tmp/project/file.swift",
                                                  position: .firstPosition)
        
        describe("the PerformMutationTesting step") {
            beforeEach {
                delegateSpy = MutationTestingDelegateSpy()
                
                state = RunCommandState()
                state.projectDirectoryURL = URL(fileURLWithPath: "/project")
                state.sourceCodeByFilePath["/tmp/project/file.swift"] = SyntaxFactory.makeBlankSourceFile()
                state.mutationPoints = [expectedMutationPoint, expectedMutationPoint]
                
                performMutationTesting = PerformMutationTesting(ioDelegate: delegateSpy)
            }
            
            context("when the baseline test run passes") {
                
                beforeEach {
                    delegateSpy.testSuiteOutcomes = [.passed, .failed, .failed]
                    result = performMutationTesting.run(with: state)
                }
                
                it("performs a mutation test for every mutation operator") {
                    expect(delegateSpy.methodCalls).to(equal([
                        // Base test suite run
                        "runTestSuite(using:savingResultsIntoFileNamed:)",
                        // First operator
                        "backupFile(at:using:)",
                        "writeFile(to:contents:)",
                        "runTestSuite(using:savingResultsIntoFileNamed:)",
                        "restoreFile(at:using:)",
                        // Second operator
                        "backupFile(at:using:)",
                        "writeFile(to:contents:)",
                        "runTestSuite(using:savingResultsIntoFileNamed:)",
                        "restoreFile(at:using:)"
                    ]))
                    
                    expect(delegateSpy.backedUpFilePaths.count) == 2
                    expect(delegateSpy.restoredFilePaths.count) == 2
                    expect(delegateSpy.backedUpFilePaths) == delegateSpy.restoredFilePaths
                    expect(delegateSpy.mutatedFileContents.first) == SyntaxFactory.makeBlankSourceFile().description
                    expect(delegateSpy.mutatedFilePaths.first) == "/tmp/project/file.swift"
                    
                }
                
                it("returns the mutation test outcomes ") {
                    let expectedTestOutcomes = [
                        MutationTestOutcome(testSuiteOutcome: .failed,
                                            mutationPoint: expectedMutationPoint,
                                            operatorDescription: "",
                                            originalProjectDirectoryUrl: URL(fileURLWithPath: "/project")),
                        
                        MutationTestOutcome(testSuiteOutcome: .failed,
                                            mutationPoint: expectedMutationPoint,
                                            operatorDescription: "",
                                            originalProjectDirectoryUrl: URL(fileURLWithPath: "/project")),
                    ]
                    
                    guard case .success(let stateChanges) = result! else {
                        fail("expected sccess but got \(String(describing: result!))")
                        return
                    }

                    expect(stateChanges) == [.mutationTestOutcomesGenerated(expectedTestOutcomes)]
                }
            }
            
            context("when the baseline test run doesn't pass") {
                context("due to a failing test") {
                    beforeEach {
                        delegateSpy.testSuiteOutcomes = [.failed]
                        result = performMutationTesting.run(with: state)
                    }
                    
                    it("doesn't perform any mutation testing") {
                        expect(delegateSpy.methodCalls).to(equal([
                            "runTestSuite(using:savingResultsIntoFileNamed:)",
                        ]))
                    }
                    
                    it("cascades a failure") {
                        guard case .failure(.mutationTestingAborted(reason: .baselineTestFailed(let log))) = result! else {
                            fail("expected a failure but got \(String(describing: result!))")
                            return
                        }
                        expect(log).notTo(beEmpty())
                    }
                }
                
                context("due to a build error") {
                    beforeEach {
                        delegateSpy.testSuiteOutcomes = [.buildError]
                        result = performMutationTesting.run(with: state)
                    }
                    
                    it("doesn't perform any mutation testing") {
                        expect(delegateSpy.methodCalls).to(equal([
                            "runTestSuite(using:savingResultsIntoFileNamed:)",
                        ]))
                    }
                    
                    it("cascades a failure") {
                        guard case .failure(.mutationTestingAborted(reason: .baselineTestFailed(let log))) = result! else {
                            fail("expected a mutationTestingAborted failure but got \(String(describing: result!))")
                            return
                        }
                        expect(log).notTo(beEmpty())
                    }
                }
                
                context("due to a runtime error") {
                    beforeEach {
                        delegateSpy.testSuiteOutcomes = [.runtimeError]
                        result = performMutationTesting.run(with: state)
                    }
                    
                    it("doesn't perform any mutation testing") {
                        expect(delegateSpy.methodCalls).to(equal([
                            "runTestSuite(using:savingResultsIntoFileNamed:)",
                        ]))
                    }
                    
                    it("cascades a failure") {
                        guard case .failure(.mutationTestingAborted(reason: .baselineTestFailed(let wrong))) = result! else {
                            fail("expected a mutationTestingAborted failure but got \(String(describing: result!))")
                            return
                        }
                        
                        expect(wrong).notTo(beEmpty())
                    }
                }
            }
            
            context("when it encounters 5 consecutive build errors in a project-under-test") {
                
                beforeEach {
                    delegateSpy.testSuiteOutcomes = [.passed, .buildError, .buildError, .buildError, .buildError, .buildError]
                    state.mutationPoints = Array(repeating: expectedMutationPoint, count: 5)
                    result = performMutationTesting.run(with: state)
                }
                
                it("aborts testing after the maximum number of attempts is reached") {
                    expect(delegateSpy.methodCalls).to(equal([
                        // Base test suite run
                        "runTestSuite(using:savingResultsIntoFileNamed:)",
                        // First operator
                        "backupFile(at:using:)",
                        "writeFile(to:contents:)",
                        "runTestSuite(using:savingResultsIntoFileNamed:)",
                        "restoreFile(at:using:)",
                        // Second operator
                        "backupFile(at:using:)",
                        "writeFile(to:contents:)",
                        "runTestSuite(using:savingResultsIntoFileNamed:)",
                        "restoreFile(at:using:)",
                        // Third operator
                        "backupFile(at:using:)",
                        "writeFile(to:contents:)",
                        "runTestSuite(using:savingResultsIntoFileNamed:)",
                        "restoreFile(at:using:)",
                        // Fourth operator
                        "backupFile(at:using:)",
                        "writeFile(to:contents:)",
                        "runTestSuite(using:savingResultsIntoFileNamed:)",
                        "restoreFile(at:using:)",
                        // Fifth operator
                        "backupFile(at:using:)",
                        "writeFile(to:contents:)",
                        "runTestSuite(using:savingResultsIntoFileNamed:)",
                        "restoreFile(at:using:)"
                    ]))
                    
                    expect(delegateSpy.backedUpFilePaths.count).to(equal(5))
                    expect(delegateSpy.restoredFilePaths.count).to(equal(5))
                    expect(delegateSpy.backedUpFilePaths).to(equal(delegateSpy.restoredFilePaths))
                expect(delegateSpy.mutatedFileContents.first).to(equal(SyntaxFactory.makeBlankSourceFile().description))
                    expect(delegateSpy.mutatedFilePaths.first).to(equal("/tmp/project/file.swift"))
                }
                
                it("cascades a failure") {
                    guard case .failure(.mutationTestingAborted(reason: .tooManyBuildErrors)) = result! else {
                        fail("expected a mutationTestingAborted failure but got \(String(describing: result!))")
                        return
                    }
                }
            }
            
            context("when it doesn't encounter 5 consecutive build errors in a project-under-test") {
                
                beforeEach {
                    delegateSpy.testSuiteOutcomes = [.passed, .buildError, .buildError, .buildError, .buildError, .failed, .passed]
                    state.mutationPoints = Array(repeating: expectedMutationPoint, count: 5)
                    
                    result = performMutationTesting.run(with: state)
                }
                
                it("performs mutation testing normally") {
                    
                    expect(delegateSpy.methodCalls).to(equal([
                        // Base test suite run
                        "runTestSuite(using:savingResultsIntoFileNamed:)",
                        // First operator
                        "backupFile(at:using:)",
                        "writeFile(to:contents:)",
                        "runTestSuite(using:savingResultsIntoFileNamed:)",
                        "restoreFile(at:using:)",
                        // Second operator
                        "backupFile(at:using:)",
                        "writeFile(to:contents:)",
                        "runTestSuite(using:savingResultsIntoFileNamed:)",
                        "restoreFile(at:using:)",
                        // Third operator
                        "backupFile(at:using:)",
                        "writeFile(to:contents:)",
                        "runTestSuite(using:savingResultsIntoFileNamed:)",
                        "restoreFile(at:using:)",
                        // Fourth operator
                        "backupFile(at:using:)",
                        "writeFile(to:contents:)",
                        "runTestSuite(using:savingResultsIntoFileNamed:)",
                        "restoreFile(at:using:)",
                        // Fifth operator
                        "backupFile(at:using:)",
                        "writeFile(to:contents:)",
                        "runTestSuite(using:savingResultsIntoFileNamed:)",
                        "restoreFile(at:using:)",
                    ]))
                    
                    expect(delegateSpy.backedUpFilePaths.count) == 5
                    expect(delegateSpy.restoredFilePaths.count) == 5
                    expect(delegateSpy.backedUpFilePaths) == delegateSpy.restoredFilePaths
                    
                    expect(delegateSpy.mutatedFileContents.first) == SyntaxFactory.makeBlankSourceFile().description
                    expect(delegateSpy.mutatedFilePaths.first) == "/tmp/project/file.swift"
                }

                it("returns the mutation test outcomes") {
                    
                    let expectedBuildErrorOutcome = MutationTestOutcome(testSuiteOutcome: .buildError,
                                                                        mutationPoint: MutationPoint(mutationOperatorId: .ror, filePath: "/tmp/project/file.swift", position: .firstPosition),
                                                                        operatorDescription: "",
                                                                        originalProjectDirectoryUrl: URL(fileURLWithPath: "/project"))
                    
                    let expectedFailingOutcome = MutationTestOutcome(testSuiteOutcome: .failed,
                                                                     mutationPoint: MutationPoint(mutationOperatorId: .ror, filePath: "/tmp/project/file.swift", position: .firstPosition),
                                                                     operatorDescription: "",
                                                                     originalProjectDirectoryUrl: URL(fileURLWithPath: "/project"))
                    
                    let expectedTestOutcomes = Array(repeating: expectedBuildErrorOutcome, count: 4) + [expectedFailingOutcome]
                    
                    guard case .success(let stateChanges) = result! else {
                        fail("expected sccess but got \(String(describing: result!))")
                        return
                    }
                    
                    expect(stateChanges) == [.mutationTestOutcomesGenerated(expectedTestOutcomes)]
                }
            }
        }
    }
}
