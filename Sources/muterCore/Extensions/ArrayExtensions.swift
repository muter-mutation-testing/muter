extension Array where Element: Hashable {
    func deduplicated() -> Array {
        Array(Set(self))
    }
}
