struct Example2 {
    func areEqualAsString(_ a: Int) -> String {
        let b = a != a 
        return b == a ? "equal" : "not equal"
    }
	
	func containSideEffects(_ a: Int) -> String {
		let b = something()
		_ = returnsSomethingThatGetsIgnored()
		voidFunctionCall()
		return ""
	}
}
