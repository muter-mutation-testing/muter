import Foundation

extension String {
    func repeated(_ times: Int) -> String {
        return (0 ..< times).reduce("") { current, _ in current + "\(self)"}
    }

    var trimmed: String {
        return trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
}
