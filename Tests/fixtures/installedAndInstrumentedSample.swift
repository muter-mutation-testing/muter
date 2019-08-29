struct Example2 {
    func areEqualAsString(_ a: Int) -> String {
CodeCoverageInstrumenter.shared.recordFunctionCall(forFunctionNamed: "Example2.areEqualAsString(_ a: Int) -> String")
        let b = a != a
        return b == a ? "equal" : "not equal"
    }
    
    func areEqualAsString(_ a: Float) -> String {
CodeCoverageInstrumenter.shared.recordFunctionCall(forFunctionNamed: "Example2.areEqualAsString(_ a: Float) -> String")
        return ""
    }
}
