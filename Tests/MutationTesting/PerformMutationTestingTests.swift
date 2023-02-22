import SwiftSyntax
import XCTest
import TestingExtensions

@testable import muterCore

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

        state.mutationMapping = [
            try makeSchemataMapping(),
            try makeSchemataMapping(),
        ]
    }

    func test_whenBaselinePasses_thenRunMutationTesting() throws {
        ioDelegate.testSuiteOutcomes = [.passed, .failed, .failed]
        
        let result = try XCTUnwrap(sut.run(with: state).get())
        
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
        ])
    }
    
    func test_createLogFile() throws {
        ioDelegate.testSuiteOutcomes = [.passed, .failed, .failed]
        
        _ = try XCTUnwrap(sut.run(with: state).get())
        
        XCTAssertEqual(
            ioDelegate.testLogs,
            [
                "baseline run",
                "path_RelationalOperatorReplacement_0_0_0.log",
                "path_RelationalOperatorReplacement_0_0_0.log"
            ]
        )
    }
    
    func test_whenBaselineFailsDueToTestingFailure() {
        ioDelegate.testSuiteOutcomes = [.failed]
        
        let result = sut.run(with: state)
        
        XCTAssertEqual(ioDelegate.methodCalls, [
            "runTestSuite(withSchemata:using:savingResultsIntoFileNamed:)",
        ])
        
        guard case let .failure(.mutationTestingAborted(reason: .baselineTestFailed(log))) = result else {
            return XCTFail("Expected failure, got \(result)")
        }
        
        XCTAssertFalse(log.isEmpty)
    }
    
    func test_whenBaselineFailsDueToBuildError() {
        ioDelegate.testSuiteOutcomes = [.buildError]
        
        let result = sut.run(with: state)
        
        XCTAssertEqual(ioDelegate.methodCalls, [
            "runTestSuite(withSchemata:using:savingResultsIntoFileNamed:)",
        ])
        
        guard case let .failure(.mutationTestingAborted(reason: .baselineTestFailed(log))) = result else {
            return XCTFail("Expected failure, got \(result)")
        }
        
        XCTAssertFalse(log.isEmpty)
    }
    
    func test_whenBaselineFailsDueToRuntimeError() {
        ioDelegate.testSuiteOutcomes = [.runtimeError]
        
        let result = sut.run(with: state)
        
        XCTAssertEqual(ioDelegate.methodCalls, [
            "runTestSuite(withSchemata:using:savingResultsIntoFileNamed:)",
        ])
        
        guard case let .failure(.mutationTestingAborted(reason: .baselineTestFailed(log))) = result else {
            return XCTFail("Expected failure, got \(result)")
        }
        
        XCTAssertFalse(log.isEmpty)
    }
    
    func test_whenEncountersFiveConsecutiveBuildErrors_thenCancelMutationTesting() throws {
        ioDelegate.testSuiteOutcomes = [
            .passed,
            .buildError,
            .buildError,
            .buildError,
            .buildError,
            .buildError
        ]

        state.mutationMapping = Array(repeating: try makeSchemataMapping(), count: 5)
        
        let result = sut.run(with: state)
        
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
        
        XCTAssertEqual(result, .failure(.mutationTestingAborted(reason: .tooManyBuildErrors)))
    }
    
    func test_whenEncountersFiveNonConsecutiveBuildErrors_thenPerformMutationTesting() throws {
        ioDelegate.testSuiteOutcomes = [
            .passed,
            .buildError,
            .buildError,
            .buildError,
            .buildError,
            .failed,
            .passed
        ]

        state.mutationMapping = Array(repeating: try makeSchemataMapping(), count: 5)

        let result = try XCTUnwrap(sut.run(with: state).get())
        
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
                    try .make(
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
