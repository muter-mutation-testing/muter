struct Example2 {
    func areEqualAsString(_ a: Int) -> String {
        // instrumented
        let b = a != a
        return b == a ? "equal" : "not equal"
    }
    
    func areEqualAsString(_ a: Float) -> String {
        // instrumented
        return ""
    }
}

