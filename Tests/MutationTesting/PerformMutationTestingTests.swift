@testable import muterCore
import SwiftSyntax
import TestingExtensions
import XCTest

final class PerformMutationTestingTests: MuterTestCase {
    private let state = RunCommandState()

    private let expectedMutationPoint = MutationPoint(
        mutationOperatorId: .ror,
        filePath: "/tmp/project/file.swift",
        position: .firstPosition
    )

    private lazy var sut = PerformMutationTesting()

    override func setUpWithError() throws {
        try super.setUpWithError()

        state.projectDirectoryURL = URL(fileURLWithPath: "/project")
        state.tempDirectoryURL = URL(fileURLWithPath: "/project_mutated")

        state.mutationMapping = try [
            makeSchemataMapping(),
            makeSchemataMapping(),
        ]
    }

    func test_whenBaselinePasses_thenRunMutationTesting() async throws {
        ioDelegate.testSuiteOutcomes = [.passed, .failed, .failed]

        let result = try await sut.run(with: state)

        XCTAssertEqual(ioDelegate.methodCalls, [
            // Base line
            "runTestSuite(withSchemata:using:savingResultsIntoFileNamed:)",
            // First mutation
            "switchOn(schemata:for:at:)",
            "runTestSuite(withSchemata:using:savingResultsIntoFileNamed:)",
            // Second mutation
            "switchOn(schemata:for:at:)",
            "runTestSuite(withSchemata:using:savingResultsIntoFileNamed:)"
        ])

        let expectedTestOutcomes = [
            MutationTestOutcome.Mutation.make(
                testSuiteOutcome: .failed,
                point: .make(
                    mutationOperatorId: .ror,
                    filePath: "/tmp/project/file.swift",
                    position: .null
                ),
                snapshot: .null,
                originalProjectDirectoryUrl: state.projectDirectoryURL,
                tempDirectoryURL: state.tempDirectoryURL
            ),
            MutationTestOutcome.Mutation.make(
                testSuiteOutcome: .failed,
                point: .make(
                    mutationOperatorId: .ror,
                    filePath: "/tmp/project/file.swift",
                    position: .null
                ),
                snapshot: .null,
                originalProjectDirectoryUrl: state.projectDirectoryURL,
                tempDirectoryURL: state.tempDirectoryURL
            ),
        ]

        XCTAssertEqual(
            result, [
                .mutationTestOutcomeGenerated(
                    MutationTestOutcome(mutations: expectedTestOutcomes)
                ),
            ]
        )
    }

    func test_createLogFile() async throws {
        ioDelegate.testSuiteOutcomes = [.passed, .failed, .failed]

        _ = try await sut.run(with: state)

        XCTAssertEqual(
            ioDelegate.testLogs,
            [
                "baseline run",
                "path_RelationalOperatorReplacement_0_0_0.log",
                "path_RelationalOperatorReplacement_0_0_0.log"
            ]
        )
    }

    func test_whenBaselineFailsDueToTestingFailure() async throws {
        ioDelegate.testSuiteOutcomes = [.failed]

        try await assertThrowsMuterError(
            await sut.run(with: state)
        ) { error in
            guard case let .mutationTestingAborted(reason: .baselineTestFailed(log)) = error else {
                XCTFail("Expected mutationTestingAborted, got \(error)")
                return
            }

            XCTAssertFalse(log.isEmpty)
        }

        XCTAssertEqual(
            ioDelegate.methodCalls,
            ["runTestSuite(withSchemata:using:savingResultsIntoFileNamed:)"]
        )
    }

    func test_whenBaselineFailsDueToBuildError() async throws {
        ioDelegate.testSuiteOutcomes = [.buildError]

        try await assertThrowsMuterError(
            await sut.run(with: state)
        ) { error in
            guard case let .mutationTestingAborted(reason: .baselineTestFailed(log)) = error else {
                XCTFail("Expected mutationTestingAborted, got \(error)")
                return
            }

            XCTAssertFalse(log.isEmpty)
        }

        XCTAssertEqual(ioDelegate.methodCalls, [
            "runTestSuite(withSchemata:using:savingResultsIntoFileNamed:)",
        ])
    }

    func test_whenBaselineFailsDueToRuntimeError() async throws {
        ioDelegate.testSuiteOutcomes = [.runtimeError]

        try await assertThrowsMuterError(
            await sut.run(with: state)
        ) { error in
            guard case let .mutationTestingAborted(reason: .baselineTestFailed(log)) = error else {
                XCTFail("Expected mutationTestingAborted, got \(error)")
                return
            }

            XCTAssertFalse(log.isEmpty)
        }

        XCTAssertEqual(ioDelegate.methodCalls, [
            "runTestSuite(withSchemata:using:savingResultsIntoFileNamed:)",
        ])
    }

    func test_whenEncountersFiveConsecutiveBuildErrors_thenCancelMutationTesting() async throws {
        ioDelegate.testSuiteOutcomes = [
            .passed,
            .buildError,
            .buildError,
            .buildError,
            .buildError,
            .buildError
        ]

        state.mutationMapping = try Array(repeating: makeSchemataMapping(), count: 5)

        try await assertThrowsMuterError(
            await sut.run(with: state),
            .mutationTestingAborted(reason: .tooManyBuildErrors)
        )

        XCTAssertEqual(ioDelegate.methodCalls, [
            "runTestSuite(withSchemata:using:savingResultsIntoFileNamed:)",
            "switchOn(schemata:for:at:)",
            "runTestSuite(withSchemata:using:savingResultsIntoFileNamed:)",
            "switchOn(schemata:for:at:)",
            "runTestSuite(withSchemata:using:savingResultsIntoFileNamed:)",
            "switchOn(schemata:for:at:)",
            "runTestSuite(withSchemata:using:savingResultsIntoFileNamed:)",
            "switchOn(schemata:for:at:)",
            "runTestSuite(withSchemata:using:savingResultsIntoFileNamed:)",
            "switchOn(schemata:for:at:)",
            "runTestSuite(withSchemata:using:savingResultsIntoFileNamed:)"
        ])
    }

    func test_whenEncountersFiveNonConsecutiveBuildErrors_thenPerformMutationTesting() async throws {
        ioDelegate.testSuiteOutcomes = [
            .passed,
            .buildError,
            .buildError,
            .buildError,
            .buildError,
            .failed,
            .passed
        ]

        state.mutationMapping = try Array(repeating: makeSchemataMapping(), count: 5)

        let result = try await sut.run(with: state)

        XCTAssertEqual(ioDelegate.methodCalls, [
            // base line
            "runTestSuite(withSchemata:using:savingResultsIntoFileNamed:)",
            "switchOn(schemata:for:at:)",
            // First operator
            "runTestSuite(withSchemata:using:savingResultsIntoFileNamed:)",
            "switchOn(schemata:for:at:)",

            "runTestSuite(withSchemata:using:savingResultsIntoFileNamed:)",
            "switchOn(schemata:for:at:)",

            "runTestSuite(withSchemata:using:savingResultsIntoFileNamed:)",
            "switchOn(schemata:for:at:)",

            "runTestSuite(withSchemata:using:savingResultsIntoFileNamed:)",
            "switchOn(schemata:for:at:)",

            "runTestSuite(withSchemata:using:savingResultsIntoFileNamed:)"
        ])

        let expectedBuildErrorOutcome = MutationTestOutcome.Mutation.make(
            testSuiteOutcome: .buildError,
            point: MutationPoint(
                mutationOperatorId: .ror,
                filePath: "/tmp/project/file.swift",
                position: .firstPosition
            ),
            snapshot: .null,
            originalProjectDirectoryUrl: URL(fileURLWithPath: "/project")
        )

        let expectedFailingOutcome = MutationTestOutcome.Mutation.make(
            testSuiteOutcome: .failed,
            point: MutationPoint(
                mutationOperatorId: .ror,
                filePath: "/tmp/project/file.swift",
                position: .firstPosition
            ),
            snapshot: .null,
            originalProjectDirectoryUrl: URL(fileURLWithPath: "/project")
        )

        let expectedTestOutcomes = Array(repeating: expectedBuildErrorOutcome, count: 4) + [expectedFailingOutcome]

        XCTAssertEqual(result, [
            .mutationTestOutcomeGenerated(
                MutationTestOutcome(mutations: expectedTestOutcomes)
            ),
        ])
    }

    private func makeSchemataMapping() throws -> SchemataMutationMapping {
        try SchemataMutationMapping.make(
            filePath: "/some/path",
            (
                source: "func bar() { }",
                schemata: [
                    .make(
                        filePath: "/tmp/project/file.swift",
                        mutationOperatorId: .ror,
                        syntaxMutation: "",
                        position: .firstPosition,
                        snapshot: .null
                    )
                ]
            )
        )
    }
}
