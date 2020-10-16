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
