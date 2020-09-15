func mutateMe() {
    bar()
}

func mutateMe2() -> Void {
    bar()
}

func bar() { }

func ignoreMe() -> Int {
    returnInt()
}

func returnInt() -> Int {
    1
}
