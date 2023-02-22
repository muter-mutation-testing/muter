import XCTest

@testable import muterCore

final class MutationTestOutcomeTests: MuterTestCase {
    func test_pathMappingWhenPathsAreDeeplyNested() {
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

        XCTAssertEqual(outcome.originalProjectPath, "/Users/user0/Code/ProjectDirectory/Subdirectory/file.swift")
    }

    func test_pathMappingWhenPathsAreShallowlyNested() {
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

        XCTAssertEqual(outcome.originalProjectPath, "/Users/user0/Code/ProjectDirectory/file.swift")
    }

    func test_pathMappingWhenPathHasSpaces() {
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

        XCTAssertEqual(outcome.originalProjectPath, "/Users/user0/Project Directory/file.swift")
    }

    func test_pathMappingWhenThePathOfAFileContainsFoldersWithTheSameName() {
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

        XCTAssertEqual(outcome.originalProjectPath, "/Users/user0/Code/ProjectDirectory/ProjectDirectory/file.swift")
    }
}
