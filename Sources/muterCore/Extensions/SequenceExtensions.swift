public extension Sequence {
    func count(_ isIncluded: (Self.Element) throws -> Bool) rethrows -> Int {
        try include(isIncluded).count
    }

    func include(_ isIncluded: (Self.Element) throws -> Bool) rethrows -> [Self.Element] {
        try filter(isIncluded)
    }

    func exclude(_ isExcluded: (Self.Element) throws -> Bool) rethrows -> [Self.Element] {
        try filter { !(try isExcluded($0)) }
    }

    func accumulate<Result>(into initialResult: Result, _ nextPartialResult: (Result, Self.Element) throws -> Result) rethrows -> Result {
        try reduce(initialResult, nextPartialResult)
    }
}
