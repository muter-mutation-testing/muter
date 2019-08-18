struct Example2 {
    func areEqualAsString(_ a: Int) -> String {
Example2.areEqualAsString(_ a: Int) -> String
        let b = a != a
        return b == a ? "equal" : "not equal"
    }

    func areEqualAsString(_ a: Float) -> String {
Example2.areEqualAsString(_ a: Float) -> String
        return ""
    }
}
