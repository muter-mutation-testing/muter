extension Array where Element: Hashable {
    func deduplicated() -> Array {
        Array(Set(self))
    }
}

extension Array {
    func any(_ predicate: (Element) -> Bool) -> Bool {
        !filter(predicate).isEmpty
    }
}
