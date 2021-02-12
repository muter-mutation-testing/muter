func f() {
    doSomething(testableSideEffect: true)
    doSomething(testableSideEffect: false)  // muter:skip
}
