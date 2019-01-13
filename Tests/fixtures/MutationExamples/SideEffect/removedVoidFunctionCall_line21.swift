struct Example {
    func containsSideEffect() -> Int {
        _ = causesSideEffect()
        return 1
    }

    func containsSideEffect() -> Int {
        print("something")

        _ = causesSideEffect()
    }

    @discardableResult
    func causesSideEffect() -> Int {
        return 0
    }

    func causesAnotherSideEffect() {
        let key = "some key"
        let value = aFunctionThatReturnsAValue()
    }

    func containsSpecialCases() {
        fatalError("this should never be deleted!")
        exit(1)
        abort()
    }

    func containsADeepMethodCall() {
        let containsIgnoredResult = statement.description.contains("_ = ")
        var anotherIgnoredResult = statement.description.contains("_ = ")
    }
}
