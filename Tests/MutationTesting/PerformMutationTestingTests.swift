import SwiftSyntax
import XCTest

@testable import muterCore

final class PerformMutationTestingTests: XCTestCase {
    private let delegate = MutationTestingDelegateSpy()
    private let state = RunCommandState()

    private let expectedMutationPoint = MutationPoint(mutationOperatorId: .ror,
                                                      filePath: "/tmp/project/file.swift",
                                                      position: .firstPosition)

    private lazy var sut = PerformMutationTesting(ioDelegate: delegate)
    
    override func setUp() {
        super.setUp()
        
        state.projectDirectoryURL = URL(fileURLWithPath: "/project")
        state.sourceCodeByFilePath["/tmp/project/file.swift"] = SyntaxFactory.makeBlankSourceFile()
        state.mutationPoints = [expectedMutationPoint, expectedMutationPoint]
    }

    func test_whenBaselinePasses_thenRunMutationTesting() throws {
        delegate.testSuiteOutcomes = [.passed, .failed, .failed]
        
        let result = try XCTUnwrap(sut.run(with: state).get())
        
        XCTAssertEqual(delegate.methodCalls, [
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
        ])
        
        XCTAssertEqual(delegate.backedUpFilePaths.count, 2)
        XCTAssertEqual(delegate.restoredFilePaths.count, 2)
        XCTAssertEqual(delegate.backedUpFilePaths, delegate.restoredFilePaths)
        XCTAssertEqual(
            delegate.mutatedFileContents.first,
            SyntaxFactory.makeBlankSourceFile().description
        )
        XCTAssertEqual(delegate.mutatedFilePaths.first, "/tmp/project/file.swift")
        
        let expectedTestOutcomes = [
            MutationTestOutcome.Mutation.make(
                testSuiteOutcome: .failed,
                point: expectedMutationPoint,
                snapshot: .null,
                originalProjectDirectoryUrl: URL(fileURLWithPath: "/project")
            ),
            MutationTestOutcome.Mutation.make(
                testSuiteOutcome: .failed,
                point: expectedMutationPoint,
                snapshot: .null,
                originalProjectDirectoryUrl: URL(fileURLWithPath: "/project")
            ),
        ]
        
        XCTAssertEqual(result, [
            .mutationTestOutcomeGenerated(
                MutationTestOutcome(mutations: expectedTestOutcomes)
            ),
        ])
    }
    
    func test_whenBaselineFailsDueToTestingFailure() {
        delegate.testSuiteOutcomes = [.failed]
        
        let result = sut.run(with: state)
        
        XCTAssertEqual(delegate.methodCalls, [
            "runTestSuite(using:savingResultsIntoFileNamed:)",
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
            "runTestSuite(using:savingResultsIntoFileNamed:)",
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
            "runTestSuite(using:savingResultsIntoFileNamed:)",
        ])
        
        guard case let .failure(.mutationTestingAborted(reason: .baselineTestFailed(log))) = result else {
            return XCTFail("Expected failure, got \(result)")
        }
        
        XCTAssertFalse(log.isEmpty)
    }
    
    func test_whenEncountersFiveConsecutiveBuildErrors_thenCancelMutationTesting() {
        delegate.testSuiteOutcomes = [.passed, .buildError, .buildError, .buildError, .buildError, .buildError]
        state.mutationPoints = Array(repeating: expectedMutationPoint, count: 5)
        
        let result = sut.run(with: state)
        
        XCTAssertEqual(delegate.methodCalls, [
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
        ])
        
        XCTAssertEqual(delegate.backedUpFilePaths.count, 5)
        XCTAssertEqual(delegate.restoredFilePaths.count, 5)
        XCTAssertEqual(delegate.backedUpFilePaths, delegate.restoredFilePaths)
        XCTAssertEqual(
            delegate.mutatedFileContents.first,
            SyntaxFactory.makeBlankSourceFile().description
        )
        XCTAssertEqual(delegate.mutatedFilePaths.first, "/tmp/project/file.swift")
        
        XCTAssertEqual(result, .failure(.mutationTestingAborted(reason: .tooManyBuildErrors)))
    }
    
    func test_whenEncountersFiveNonConsecutiveBuildErrors_thenPerformMutationTesting() throws {
        delegate.testSuiteOutcomes = [.passed, .buildError, .buildError, .buildError, .buildError, .failed, .passed]
        state.mutationPoints = Array(repeating: expectedMutationPoint, count: 5)
        
        let result = try XCTUnwrap(sut.run(with: state).get())
        
        XCTAssertEqual(delegate.methodCalls, [
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
        ])
        
        XCTAssertEqual(delegate.backedUpFilePaths.count, 5)
        XCTAssertEqual(delegate.restoredFilePaths.count, 5)
        XCTAssertEqual(delegate.backedUpFilePaths, delegate.restoredFilePaths)
        XCTAssertEqual(
            delegate.mutatedFileContents.first,
            SyntaxFactory.makeBlankSourceFile().description
        )
        XCTAssertEqual(delegate.mutatedFilePaths.first, "/tmp/project/file.swift")
        
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
}
