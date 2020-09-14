func mutateMe() {
    bar()
}

func mutateMe2() -> Void {
    bar()
}

func mutateMe3() -> () {
    bar()
}

func bar() { }

func ignoreMe() -> Int {
    returnInt()
}

func ignoreMe2() -> Int {
    return returnInt()
}

func returnInt() -> Int {
    1
}
