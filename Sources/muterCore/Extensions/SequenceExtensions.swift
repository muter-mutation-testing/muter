public extension Sequence {
    func count(_ isIncluded: (Self.Element) throws -> Bool) rethrows -> Int {
        return try include(isIncluded).count
    }

    func include(_ isIncluded: (Self.Element) throws -> Bool) rethrows -> [Self.Element] {
        return try filter(isIncluded)
    }

    func exclude(_ isExcluded: (Self.Element) throws -> Bool) rethrows -> [Self.Element] {
        return try filter { !(try isExcluded($0)) }
    }

    func accumulate<Result>(into initialResult: Result, _ nextPartialResult: (Result, Self.Element) throws -> Result) rethrows -> Result {
        return try reduce(initialResult, nextPartialResult)
    }
}
