class CodeCoverageInstrumenter {
    static let shared = CodeCoverageInstrumenter() {
        functionCallCounts in
        print("we cookin' with gas")
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
