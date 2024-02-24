import Foundation

extension String {
    func repeated(_ times: Int) -> String { (0 ..< times).reduce("") { current, _ in current + "\(self)" } }

    func removingSubrange(_ bounds: Range<String.Index>?) -> String {
        guard let bounds else {
            return self
        }
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

    func distance(to index: Index) -> Int {
        distance(from: startIndex, to: index)
    }

    var nilIfEmpty: String? {
        !isEmpty ? self : nil
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

    func matches(
        _ pattern: String,
        options: NSRegularExpression.Options = []
    ) -> Bool {
        !NSRegularExpression
            .regexWithPattern(pattern, options)
            .matches(
                in: self,
                options: [],
                range: stringRange
            ).isEmpty
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
        guard let range = Range(nsrange, in: self) else {
            return self
        }
        return String(self[range])
    }
}

extension String {
    /// Converts a UTF-8 byte offset to a character offset in the given string.
    ///
    /// - Parameters:
    ///   - utf8Offset: The UTF-8 byte offset to be converted.
    /// - Returns: The corresponding character offset if the conversion is successful, or `nil` if can't convert to corresponding char offset.
    ///
    /// - Complexity: O(*n*), where *n* is the number of characters in the string.
    func convertToCharOffset(from utf8Offset: Int) -> Int? {
        guard utf8Offset >= 0 && utf8Offset <= utf8.count else {
            return nil
        }

        var charOffset = 0
        var currentUtf8Offset = 0

        for char in self {
            if currentUtf8Offset == utf8Offset {
                return charOffset
            }
            
            if currentUtf8Offset > utf8Offset {
                return nil
            }
            
            currentUtf8Offset += char.utf8.count
            charOffset += 1
        }

        return nil
    }

}
