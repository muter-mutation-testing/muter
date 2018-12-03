extension Array where Element: Hashable  {
    var deduplicated: Array {
        return Set<Element>(self).map{ $0 }
    }
}
