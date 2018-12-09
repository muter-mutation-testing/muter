extension Array where Element: Hashable  {
    func deduplicated() -> Array {
        return Set(self).map{ $0 }
    }
}
