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

    /// Splits the array into chunks of the specified size
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
