struct Example2 {
    func areEqualAsString(_ a: Int) -> String {
        // instrumented
        let b = a != a
        return b == a ? "equal" : "not equal"
    }
    
    func areAlsoEqualAsString(_ a: Int) -> String {
        // instrumented
        return ""
    }
}

