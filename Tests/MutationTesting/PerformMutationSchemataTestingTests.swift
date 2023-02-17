import SwiftSyntax
import XCTest
import TestingExtensions

@testable import muterCore

final class PerformMutationSchemataTestingTests: XCTestCase {
    private let delegate = MutationTestingDelegateSpy()
    private let state = RunCommandState()

    private let expectedMutationPoint = MutationPoint(
        mutationOperatorId: .ror,
        filePath: "/tmp/project/file.swift",
        position: .firstPosition
    )

    private lazy var sut = PerformMutationSchemataTesting(ioDelegate: delegate)

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
        delegate.testSuiteOutcomes = [.passed, .failed, .failed]
        
        let result = try XCTUnwrap(sut.run(with: state).get())
        
        XCTAssertEqual(delegate.methodCalls, [
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
        delegate.testSuiteOutcomes = [.passed, .failed, .failed]
        
        _ = try XCTUnwrap(sut.run(with: state).get())
        
        XCTAssertEqual(delegate.testLogs, [
            "baseline run",
            "Debug_RelationalOperatorReplacement_0_0_0.log",
            "Debug_RelationalOperatorReplacement_0_0_0.log"
        ])
    }
    
    func test_whenBaselineFailsDueToTestingFailure() {
        delegate.testSuiteOutcomes = [.failed]
        
        let result = sut.run(with: state)
        
        XCTAssertEqual(delegate.methodCalls, [
            "runTestSuite(withSchemata:using:savingResultsIntoFileNamed:)",
        ])
        
        guard case let .failure(.mutationTestingAborted(reason: .baselineTestFailed(log))) = result else {
            return XCTFail("Expected failure, got \(result)")
        }
        
        XCTAssertFalse(log.isEmpty)
    }
    
    func test_whenBaselineFailsDueToBuildError() {
        delegate.testSuiteOutcomes = [.buildError]
        
        let result = sut.run(with: state)
        
        XCTAssertEqual(delegate.methodCalls, [
            "runTestSuite(withSchemata:using:savingResultsIntoFileNamed:)",
        ])
        
        guard case let .failure(.mutationTestingAborted(reason: .baselineTestFailed(log))) = result else {
            return XCTFail("Expected failure, got \(result)")
        }
        
        XCTAssertFalse(log.isEmpty)
    }
    
    func test_whenBaselineFailsDueToRuntimeError() {
        delegate.testSuiteOutcomes = [.runtimeError]
        
        let result = sut.run(with: state)
        
        XCTAssertEqual(delegate.methodCalls, [
            "runTestSuite(withSchemata:using:savingResultsIntoFileNamed:)",
        ])
        
        guard case let .failure(.mutationTestingAborted(reason: .baselineTestFailed(log))) = result else {
            return XCTFail("Expected failure, got \(result)")
        }
        
        XCTAssertFalse(log.isEmpty)
    }
    
    func test_whenEncountersFiveConsecutiveBuildErrors_thenCancelMutationTesting() throws {
        delegate.testSuiteOutcomes = [
            .passed,
            .buildError,
            .buildError,
            .buildError,
            .buildError,
            .buildError
        ]

        state.mutationMapping = Array(repeating: try makeSchemataMapping(), count: 5)
        
        let result = sut.run(with: state)
        
        XCTAssertEqual(delegate.methodCalls, [
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
        delegate.testSuiteOutcomes = [
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
        
        XCTAssertEqual(delegate.methodCalls, [
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
            (
                source: "func bar() { }",
                schematas: [
                    try .make(
                        id: "0",
                        filePath: "/tmp/project/file.swift",
                        mutationOperatorId: .ror,
                        syntaxMutation: "",
                        positionInSourceCode: .firstPosition,
                        snapshot: .null
                    )
                ]
            )
        )
    }
}
