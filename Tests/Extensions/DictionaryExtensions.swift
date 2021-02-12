public extension Dictionary where Key == String, Value == Any {
    func recursivelyFiltered(includingKeysMatching shouldInclude: @escaping (String) -> Bool) -> [String: Any] {
        var filteredDictionary: [String: Any] = [:]
        

        for (key, value) in self where shouldInclude(key) {
            if let valueAsDictionary = value as? [String: Any] {
                filteredDictionary[key] = valueAsDictionary.recursivelyFiltered(includingKeysMatching: shouldInclude)
            } else if let valueAsArray = value as? [[String: Any]] {
                filteredDictionary[key] = valueAsArray.map { $0.recursivelyFiltered(includingKeysMatching: shouldInclude) }
            } else {
                filteredDictionary[key] = value
            }
        }
        
        return filteredDictionary
    }
}
