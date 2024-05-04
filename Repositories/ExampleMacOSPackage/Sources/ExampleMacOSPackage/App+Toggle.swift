extension App {
    static func toggle() {
        globalToggle.toggle()
    }
}

private var globalToggle: Bool = false