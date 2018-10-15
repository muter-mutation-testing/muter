struct Example {
    func something(_ a: Int) -> String {
        let b = a == 5
        if a == 10 {
            return "hello"
        }
        return a == 9 ? "goodbye" : "what"
    }
}
