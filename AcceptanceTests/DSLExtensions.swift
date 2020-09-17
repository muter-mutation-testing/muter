import Quick

func they(_ description: String, flags: FilterFlags = [:], closure: @escaping () -> Void) {
    it("they " + description, flags: flags, closure: closure)
}

func fthey(_ description: String, flags: FilterFlags = [:], closure: @escaping () -> Void) {
    fit(description, flags: flags, closure: closure)
}

func when(_ description: String, flags: FilterFlags = [:], closure: () -> Void) {
    context("when " + description, flags: flags, closure: closure)
}
