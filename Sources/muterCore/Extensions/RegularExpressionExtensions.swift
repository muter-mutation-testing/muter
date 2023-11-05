import Foundation

extension NSRegularExpression {
    static func regexWithPattern(
        _ pattern: String,
        _ options: NSRegularExpression.Options = []
    ) -> NSRegularExpression {
        let currentThread = Thread.current
        let cacheKey = pattern + "\(options)"
        if let cached = currentThread.threadDictionary[cacheKey] as? NSRegularExpression {
            return cached
        }

        let regex = try! NSRegularExpression(pattern: pattern, options: options)
        currentThread.threadDictionary[cacheKey] = regex

        return regex
    }
}
