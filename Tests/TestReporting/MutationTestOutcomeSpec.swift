import Quick
import Nimble
import Foundation
@testable import muterCore

class MutationTestOutcomeSpec: QuickSpec {
    override func spec() {
        describe("MutationTestOutcome") {
            describe("how it converts paths") {
                context("when the path of a file with a mutation point is deeply nested") {
                    it("maps the paths") {
                        let mutationPoint = MutationPoint(
                            mutationOperatorId: .logicalOperator,
                            filePath: "/var/tmp/nonsense/ProjectDirectory/Subdirectory/file.swift",
                            position: .firstPosition
                        )
                        
                        let outcome = MutationTestOutcome.Mutation.make(
                            testSuiteOutcome: .failed,
                            point: mutationPoint,
                            snapshot: .null,
                            originalProjectDirectoryUrl: URL(fileURLWithPath: "/Users/user0/Code/ProjectDirectory"),
                            tempDirectoryURL: URL(fileURLWithPath: "/var/tmp/nonsense/ProjectDirectory")
                        )
                        
                        expect(outcome.originalProjectPath) == "/Users/user0/Code/ProjectDirectory/Subdirectory/file.swift"
                    }
                }
                
                context("when the path of a file with a mutation point is shallowly nested") {
                    it("maps the paths") {
                        let mutationPoint = MutationPoint(
                            mutationOperatorId: .logicalOperator,
                            filePath: "/tmp/ProjectDirectory/file.swift",
                            position: .firstPosition
                        )
                        
                        let outcome = MutationTestOutcome.Mutation.make(
                            testSuiteOutcome: .failed,
                            point: mutationPoint,
                            snapshot: .null,
                            originalProjectDirectoryUrl: URL(fileURLWithPath: "/Users/user0/Code/ProjectDirectory"),
                            tempDirectoryURL: URL(fileURLWithPath: "/var/tmp/nonsense/ProjectDirectory")
                        )

                        expect(outcome.originalProjectPath) == "/Users/user0/Code/ProjectDirectory/file.swift"
                        
                    }
                }
                
                context("when the path of a file with a mutation point has spaces") {
                    it("maps the paths") {
                        let mutationPoint = MutationPoint(
                            mutationOperatorId: .logicalOperator,
                            filePath: "/tmp/Project Directory/file.swift",
                            position: .firstPosition
                        )
                        
                        let outcome = MutationTestOutcome.Mutation.make(
                            testSuiteOutcome: .failed,
                            point: mutationPoint,
                            snapshot: .null,
                            originalProjectDirectoryUrl: URL(fileURLWithPath: "/Users/user0/Project Directory"),
                            tempDirectoryURL: URL(fileURLWithPath: "/var/tmp/nonsense/Project Directory")
                        )

                        expect(outcome.originalProjectPath) == "/Users/user0/Project Directory/file.swift"
                    }
                }
                
                context("when the path of a file with a mutation contains folders with the same name") {
                    it("maps the paths") {
                        let mutationPoint = MutationPoint(
                            mutationOperatorId: .logicalOperator,
                            filePath: "/var/tmp/nonsense/ProjectDirectory/ProjectDirectory/file.swift",
                            position: .firstPosition
                        )
                        
                        let outcome = MutationTestOutcome.Mutation.make(
                            testSuiteOutcome: .failed,
                            point: mutationPoint,
                            snapshot: .null,
                            originalProjectDirectoryUrl: URL(fileURLWithPath: "/Users/user0/Code/ProjectDirectory"),
                            tempDirectoryURL: URL(fileURLWithPath: "/var/tmp/nonsense/ProjectDirectory")
                        )
                        
                        expect(outcome.originalProjectPath) == "/Users/user0/Code/ProjectDirectory/ProjectDirectory/file.swift"
                    }
                }
            }
        }
    }
}
