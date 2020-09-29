// this space left intentionally blank
//

func containSideEffects(_ a: Int) -> String {
    let b = something()
    _ = returnsSomethingThatGetsIgnored()
    voidFunctionCall()
    return ""
}
