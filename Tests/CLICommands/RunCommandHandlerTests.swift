//import XCTest
//import TestingExtensions
//
//@testable import muterCore
//
//final class RunCommandHandlerTests: XCTestCase {
//    private let stepSpy1 = RunCommandStepSpy()
//    private let stepSpy2 = RunCommandStepSpy()
//    private let stepSpy3 = RunCommandStepSpy()
//    private let state = RunCommandState()
//    
//    private lazy var sut = RunCommandHandler(
//        steps: [stepSpy1, stepSpy2, stepSpy3],
//        state: state
//    )
//    
//    func test_whenThereAreNoFailuresInAnyOfItSteps() throws {
//        givenThereAreNoFailuresInAnyOfItSteps()
//        
//        let expectedState = state
//        
//        try sut.run()
//        
//        let assertThatRunsAllItsSteps = {
//            XCTAssertEqual(self.stepSpy1.methodCalls, ["run(with:)"])
//            XCTAssertEqual(self.stepSpy2.methodCalls, ["run(with:)"])
//            XCTAssertEqual(self.stepSpy3.methodCalls, ["run(with:)"])
//        }
//        
//        let assertThatSharesTheSameStateAcrossAllOfTheSteps = {
//            XCTAssertTrue(self.stepSpy1.states.first === expectedState)
//            XCTAssertTrue(self.stepSpy2.states.first === expectedState)
//            XCTAssertTrue(self.stepSpy3.states.first === expectedState)
//        }
//        
//        let assertThatReturnsSuccess = {
//            XCTAssertEqual(expectedState.tempDirectoryURL, URL(string: "/lol/son")!)
//            XCTAssertEqual(expectedState.projectDirectoryURL, URL(string: "/lol")!)
//        }
//        
//        assertThatRunsAllItsSteps()
//        assertThatSharesTheSameStateAcrossAllOfTheSteps()
//        assertThatReturnsSuccess()
//    }
//    
//    private func givenThereAreNoFailuresInAnyOfItSteps() {
//        stepSpy1.resultToReturn = .success([.tempDirectoryUrlCreated(URL(string: "/lol/son")!)])
//        stepSpy2.resultToReturn = .success([.projectDirectoryUrlDiscovered(URL(string: "/lol")!)])
//        stepSpy3.resultToReturn = .success([])
//    }
//    
//    func test_whenThereIsAFailureInOneOfItsSteps() {
//        givenThereIsAFailureInOneOfItsSteps()
//        
//        XCTAssertThrowsError(try sut.run()) { error in
//            guard case .configurationParsingError = error as? MuterError else {
//                XCTFail("expected a configuration failure but got \(String(describing: error))")
//                return
//            }
//        }
//        
//        let assertThatWontRunAnySubsequentStepsAfterTheFailingStep = {
//            XCTAssertEqual(self.stepSpy1.methodCalls, ["run(with:)"])
//            XCTAssertEqual(self.stepSpy2.methodCalls, ["run(with:)"])
//            XCTAssertTrue(self.stepSpy3.methodCalls.isEmpty)
//        }
//        
//        let assertThatWontShareTheStateWithAnySubsequentStepsAfterTheFailingStep = {
//            XCTAssertTrue(self.stepSpy1.states.first === self.state)
//            XCTAssertTrue(self.stepSpy2.states.first === self.state)
//            XCTAssertTrue(self.stepSpy3.states.isEmpty)
//        }
//        
//        assertThatWontRunAnySubsequentStepsAfterTheFailingStep()
//        assertThatWontShareTheStateWithAnySubsequentStepsAfterTheFailingStep()
//    }
//    
//    private func givenThereIsAFailureInOneOfItsSteps() {
//        stepSpy1.resultToReturn = .success([])
//        stepSpy2.resultToReturn = .failure(.configurationParsingError(reason: ""))
//        stepSpy3.resultToReturn = .success([])
//    }
//    
//    func test_steps_whenSkipsCoverage() {
//        sut = RunCommandHandler(options: .make(skipCoverage: true))
//        
//        XCTAssertEqual(sut.steps.count, 8)
//        
//        XCTAssertTypeEqual(sut.steps[safe: 0], LoadConfiguration.self)
//        XCTAssertTypeEqual(sut.steps[safe: 1], CreateTempDirectoryURL.self)
//        XCTAssertTypeEqual(sut.steps[safe: 1], CreateTempDirectoryURL.self)
//        XCTAssertTypeEqual(sut.steps[safe: 2], RemoveProjectFromPreviousRun.self)
//        XCTAssertTypeEqual(sut.steps[safe: 3], CopyProjectToTempDirectory.self)
//        XCTAssertTypeEqual(sut.steps[safe: 4], DiscoverSourceFiles.self)
//        XCTAssertTypeEqual(sut.steps[safe: 5], DiscoverMutationPoints.self)
//        XCTAssertTypeEqual(sut.steps[safe: 6], GenerateSwapFilePaths.self)
//        XCTAssertTypeEqual(sut.steps[safe: 7], PerformMutationTesting.self)
//    }
//    
//    func test_steps_whenDontSkipCoverage() {
//        sut = RunCommandHandler(options: .make(skipCoverage: false))
//        
//        XCTAssertEqual(sut.steps.count, 9)
//        
//        XCTAssertTypeEqual(sut.steps[safe: 0], LoadConfiguration.self)
//        XCTAssertTypeEqual(sut.steps[safe: 1], CreateTempDirectoryURL.self)
//        XCTAssertTypeEqual(sut.steps[safe: 2], RemoveProjectFromPreviousRun.self)
//        XCTAssertTypeEqual(sut.steps[safe: 3], CopyProjectToTempDirectory.self)
//        XCTAssertTypeEqual(sut.steps[safe: 4], DiscoverProjectCoverage.self)
//        XCTAssertTypeEqual(sut.steps[safe: 5], DiscoverSourceFiles.self)
//        XCTAssertTypeEqual(sut.steps[safe: 6], DiscoverMutationPoints.self)
//        XCTAssertTypeEqual(sut.steps[safe: 7], GenerateSwapFilePaths.self)
//        XCTAssertTypeEqual(sut.steps[safe: 8], PerformMutationTesting.self)
//    }
//}
