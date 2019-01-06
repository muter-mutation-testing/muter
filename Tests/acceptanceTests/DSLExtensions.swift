import Quick

func they(_ description: String, flags: FilterFlags = [:], closure: @escaping () -> Void) {
    it(description, flags: flags, closure: closure)
}

func fthey(_ description: String, flags: FilterFlags = [:], closure: @escaping () -> Void) {
    fit(description, flags: flags, closure: closure)
}
