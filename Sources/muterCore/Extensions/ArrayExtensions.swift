extension Array where Element: Hashable {
    func deduplicated() -> Array {
        Array(Set(self))
    }
}

extension Array {
    func any(_ predicate: (Element) -> Bool) -> Bool {
        !filter(predicate).isEmpty
    }

    subscript(safe index: Int) -> Self.Element? {
        indices.contains(index) ? self[index] : nil
    }
}
