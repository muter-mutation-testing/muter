@testable import muterCore
import Foundation
import SwiftSyntax
import Quick
import Nimble

@available(OSX 10.13, *)
class GenerateCodeCoverageReport: RunCommandStep {
    private let ioDelegate: MutationTestingIODelegate
    private let instrumentationVisitor: InstrumentationVisitor
    
    init(ioDelegate: MutationTestingIODelegate = MutationTestingDelegate()) {
        self.ioDelegate = ioDelegate
        self.instrumentationVisitor = InstrumentationVisitor()
    }

    func run(with state: AnyRunCommandState) -> Result<[RunCommandState.Change], MuterError> {
        for (path, source) in state.sourceCodeByFilePath {
            ioDelegate.backupFile(at: path, using: state.swapFilePathsByOriginalPath)
            let instrumentedSource = instrumentationVisitor.visit(source)
            try! ioDelegate.writeFile(to: path, contents: instrumentedSource.description)
        }
        
        let (result, log) = ioDelegate.runTestSuite(using: state.muterConfiguration, savingResultsIntoFileNamed: "code coverage report")
        
        for (path, _) in state.sourceCodeByFilePath {
            ioDelegate.restoreFile(at: path, using: state.swapFilePathsByOriginalPath)
        }
        
        return .success([codeCoverageReport(from: log)])
    }
    
    private func codeCoverageReport(from testLog: String) -> RunCommandState.Change {
        let json = testLog.split(separator: "\n")
            .drop { $0 != "******BEGIN CODE COVERAGE REPORT******" }
            .dropFirst()
            .joined()
        let coverageReport = try! JSONDecoder().decode(CodeCoverageReport.self, from: json.data(using: .utf8)!)
        
        
        return .codeCoverageReportGenerated(coverageReport)
    }
}

@available(OSX 10.13, *)
class GenerateCodeCoverageReportSpec: QuickSpec {
    override func spec() {
        
        var generateCodeCoverageReport: GenerateCodeCoverageReport!
        var delegateSpy: MutationTestingDelegateSpy!
        var state: RunCommandState!
        var result: Result<[RunCommandState.Change], MuterError>!
        
        describe("the GenerateCodeCoverageReport step") {
            beforeEach {
                
                delegateSpy = MutationTestingDelegateSpy()
                delegateSpy.testSuiteOutcomes = [.passed]
                delegateSpy.testLogs = ["""
                testLog nonsense
                ignore meeeeee
                ******BEGIN CODE COVERAGE REPORT******
                {
                    "functionCallCounts": {
                        "Example2.areEqualAsString(_ a: Int) -> String": 0,
                        "Example2.areEqualAsString(_ a: Float) -> String": 5
                    }
                }
                """]
                
                
                state = RunCommandState()
                state.projectDirectoryURL = URL(fileURLWithPath: "/project")
                state.swapFilePathsByOriginalPath = ["/tmp/project/file1.swift": "/tmp/project/muter_tmp/file1.swift",
                                                     "/tmp/project/file2.swift": "/tmp/project/muter_tmp/file2.swift"]
                
                let uninstrumentedSample = sourceCode(fromFileAt: "\(self.fixturesDirectory)/uninstrumentedSample.swift")!
                state.sourceCodeByFilePath = ["/tmp/project/file1.swift": uninstrumentedSample,
                                              "/tmp/project/file2.swift": uninstrumentedSample]

                generateCodeCoverageReport = GenerateCodeCoverageReport(ioDelegate: delegateSpy)
                result = generateCodeCoverageReport.run(with: state)
            }
        
            it("backs up, overwrites, generates a code coverage report for, then restores, the source code it's instrumenting") {
                expect(delegateSpy.methodCalls).to(equal([
                    // First file
                    "backupFile(at:using:)",
                    "writeFile(to:contents:)",
                    // Second file
                    "backupFile(at:using:)",
                    "writeFile(to:contents:)",
                    // Generate report
                    "runTestSuite(using:savingResultsIntoFileNamed:)",
                    // Remove instrumention
                    "restoreFile(at:using:)",
                    "restoreFile(at:using:)"
                ]))
                
                expect(delegateSpy.backedUpFilePaths.count) == 2
                expect(delegateSpy.restoredFilePaths.count) == 2
                expect(delegateSpy.backedUpFilePaths) == delegateSpy.restoredFilePaths

                expect(delegateSpy.mutatedFilePaths.sorted()) == ["/tmp/project/file1.swift",
                                                                  "/tmp/project/file2.swift"]
            }
            
            it("installs the instrumentation logic into the source code") {
                fail()
            }
            
            it("instruments the source code under consideration for mutation testing so it can determine if it's reachable from a test") {
                let expectedSource = sourceCode(fromFileAt: "\(self.fixturesDirectory)/realisticInstrumentedSample.swift")!.description.dropLast() // this is a hack to make whitespace characters visible
                expect(delegateSpy.mutatedFileContents.map { $0.dropLast() }) == [expectedSource, expectedSource]
            }
            
            it("installs a hook into the test suite so it can receive the generated report after the test suite finishes") {
                fail()
            }
            
            it("returns the generated code coverage report") {
                guard case .success(let stateChanges) = result! else {
                    fail("expected success but got \(String(describing: result!))")
                    return
                }
                
                expect(stateChanges) == [.codeCoverageReportGenerated(CodeCoverageReport(functionCallCounts: ["Example2.areEqualAsString(_ a: Int) -> String" : 0,
                                                                                                              "Example2.areEqualAsString(_ a: Float) -> String": 5]))]
            }
            
            it("cascades the error") {
                guard case .failure(let reason) = result! else {
                    fail("expected success but got \(String(describing: result!))")
                    return
                }
                
                fail("what happened dog?")
            }
        }
    }
}
