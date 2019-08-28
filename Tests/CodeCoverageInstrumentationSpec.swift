import Quick
import Nimble
@testable import muterCore

class CodeCoverageInstrumenterSpec: QuickSpec {
    
    override func spec() {
        describe("CodeCoverageInstrumenter") {
            it("records the strings that get passed to it") {
                let instrumenter = CodeCoverageInstrumenter() { _ in /* no op */ }
                
                expect(instrumenter.functionCallCounts[#function]).to(beNil())
                
                instrumenter.recordFunctionCall(forFunctionNamed: #function)
                
                expect(instrumenter.functionCallCounts[#function]) == 1
                
                instrumenter.recordFunctionCall(forFunctionNamed: #function)
                
                expect(instrumenter.functionCallCounts[#function]) == 2
            }
            
            it("uses its persistence handler") {
                var recordedFunctionInvocations: [String: Int]?
                let persistenceSpy = {
                    recordedFunctionInvocations = $0
                }
                
                let instrumenter = CodeCoverageInstrumenter(persistenceHandler: persistenceSpy)
                
                instrumenter.recordFunctionCall(forFunctionNamed: #function)
                instrumenter.recordFunctionCall(forFunctionNamed: #function)
                
                instrumenter.persistFunctionCalls()
                
                expect(recordedFunctionInvocations?[#function]) == 2
            }
        }
    }
}
