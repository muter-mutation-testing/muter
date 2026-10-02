@testable import muterCore
import SwiftSyntax
import TestingExtensions
import XCTest

/// The default test timeout and parallel workers.
final class PerformMutationTestingParallelTests: MuterTestCase {
    private let state = MutationTestState()
    private let workerClone = URL(fileURLWithPath: "/project_mutated_worker1")
    private var clonedCounts: [Int] = []
    private var removedClones: [[URL]] = []

    private lazy var sut = PerformMutationTesting(
        makeWorkerDirectories: { [unowned self] _, count in
            clonedCounts.append(count)
            return Array(repeating: workerClone, count: count)
        },
        removeWorkerDirectories: { [unowned self] in removedClones.append($0) }
    )

    override func setUpWithError() throws {
        try super.setUpWithError()

        state.projectDirectoryURL = URL(fileURLWithPath: "/project")
        state.mutatedProjectDirectoryURL = URL(fileURLWithPath: "/project_mutated")
        state.mutationMapping = try [makeSchemataMapping(line: 1), makeSchemataMapping(line: 2)]
    }

    func test_withoutATimeout_mutantsGetTheMinimumDefault() async throws {
        ioDelegate.testSuiteOutcomes = [.passed, .failed, .failed]

        _ = try await sut.run(with: state)

        // The spy's baseline returns at once, so the minimum applies.
        XCTAssertEqual(
            ioDelegate.configurations.map(\.testSuiteTimeout),
            [PerformMutationTesting.minimumDefaultTimeout, PerformMutationTesting.minimumDefaultTimeout]
        )
    }

    func test_aConfiguredTimeoutIsKept() async throws {
        state.muterConfiguration = MuterConfiguration(testSuiteTimeOut: 42)
        ioDelegate.testSuiteOutcomes = [.passed, .failed, .failed]

        _ = try await sut.run(with: state)

        XCTAssertEqual(ioDelegate.configurations.map(\.testSuiteTimeout), [42, 42])
    }

    func test_withTwoWorkers_eachMutantRunsInAWorkerDirectory() async throws {
        state.muterConfiguration = MuterConfiguration(
            executable: "/usr/bin/swift", arguments: ["test"], mutationTestWorkers: 2
        )
        ioDelegate.testSuiteOutcomes = [.passed, .failed, .passed]

        let result = try await sut.run(with: state)

        XCTAssertEqual(clonedCounts, [1])
        XCTAssertEqual(removedClones, [[workerClone]])
        XCTAssertEqual(
            ioDelegate.methodCalls.filter { $0.hasPrefix("runTestSuite") },
            Array(repeating: "runTestSuite(withSchemata:using:savingResultsIntoFileNamed:workingDirectory:)", count: 2)
        )
        XCTAssertFalse(ioDelegate.methodCalls.contains("switchOn(schemata:for:at:)"))
        XCTAssertEqual(
            Set(ioDelegate.workingDirectories),
            [state.mutatedProjectDirectoryURL, workerClone]
        )

        // Outcomes keep the mutants' order, whichever worker finished first.
        guard case let .mutationTestOutcomeGenerated(outcome) = result.first else {
            return XCTFail("Expected an outcome, got \(result)")
        }
        XCTAssertEqual(outcome.mutations.map(\.point.position.line), [1, 2])
    }

    func test_workersAreCappedAtTheNumberOfMutants() async throws {
        state.muterConfiguration = MuterConfiguration(
            executable: "/usr/bin/swift", arguments: ["test"], mutationTestWorkers: 8
        )
        ioDelegate.testSuiteOutcomes = [.passed, .failed, .failed]

        _ = try await sut.run(with: state)

        XCTAssertEqual(clonedCounts, [1], "two mutants need one clone, not seven")
    }

    func test_xcodebuildProjectsIgnoreWorkers() async throws {
        state.muterConfiguration = MuterConfiguration(
            executable: "/usr/bin/xcodebuild", arguments: ["test"], mutationTestWorkers: 4
        )
        ioDelegate.testSuiteOutcomes = [.passed, .failed, .failed]

        _ = try await sut.run(with: state)

        XCTAssertEqual(clonedCounts, [])
        XCTAssertEqual(
            ioDelegate.methodCalls.filter { $0.hasPrefix("runTestSuite") },
            Array(repeating: "runTestSuite(withSchemata:using:savingResultsIntoFileNamed:)", count: 2)
        )
    }

    private func makeSchemataMapping(line: Int) throws -> SchemataMutationMapping {
        try SchemataMutationMapping.make(
            filePath: "/some/path",
            (
                source: "func bar() { }",
                schemata: [
                    .make(
                        filePath: "/tmp/project/file.swift",
                        mutationOperatorId: .ror,
                        syntaxMutation: "",
                        position: MutationPosition(utf8Offset: line, line: line, column: 0),
                        snapshot: .null
                    ),
                ]
            )
        )
    }
}
