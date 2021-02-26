import Foundation

extension String {
    func repeated(_ times: Int) -> String { (0 ..< times).reduce("") { current, _ in current + "\(self)"} }
    
    func removingSubrange(_ bounds: Range<String.Index>?) -> String {
        guard let bounds = bounds else { return self }
        var result = self
        result.removeSubrange(bounds)
        return result
    }

    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }

    var inlined: String {
        components(separatedBy: .newlines)
            .map { $0.trimmed }
            .joined(separator: " ")
    }
}

extension String {
    private var stringRange: NSRange { NSRange(location: 0, length: count) }

    func stringsMatchingRegex(
        _ pattern: String,
        options: NSRegularExpression.Options = []
    ) -> [String] {
        NSRegularExpression
            .regexWithPattern(pattern, options)
            .matches(
                in: self,
                options: [],
                range: stringRange
            )
            .map { String(substring(with: $0.range)) }
    }
    
    func firstMatchOf(
        _ pattern: String,
        options: NSRegularExpression.Options = []
    ) -> String? {
        NSRegularExpression
            .regexWithPattern(pattern, options)
            .firstMatch(
                in: self,
                options: [],
                range: stringRange
            )
            .map { String(substring(with: $0.range)) }
    }

    private func substring(with nsrange: NSRange) -> String {
        guard let range = Range(nsrange, in: self) else { return self }
        return String(self[range])
    }
}
