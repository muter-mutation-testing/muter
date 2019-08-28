import Foundation

class CodeCoverageInstrumenter {
    static let shared = CodeCoverageInstrumenter() {
        functionCallCounts in
        
//        let report = CodeCoverageReport(functionCallCounts: functionCallCounts)
//        print("****** BEGIN COVERAGE REPORT ******")
        print(functionCallCounts)
    }
    
    private(set) var functionCallCounts: [String: Int] = [:]
    private let persistenceHandler: ([String: Int]) -> Void
    
    init(persistenceHandler: @escaping ([String: Int]) -> Void) {
        self.persistenceHandler = persistenceHandler
    }
    
    func recordFunctionCall(forFunctionNamed name: String) {
        functionCallCounts[name, default: 0] += 1
    }
    
    func persistFunctionCalls() {
        persistenceHandler(functionCallCounts)
    }
}
