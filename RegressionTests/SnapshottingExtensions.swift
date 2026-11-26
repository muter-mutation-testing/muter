import Foundation
import SnapshotTesting

extension Snapshotting where Value: Encodable, Format == String {
    /// - Parameters:
    ///   - predicate: Keys to leave out of the snapshot.
    ///   - transform: Rewrites a value before it is written. It receives the value's key.
    static func json(
        excludingKeysMatching predicate: @escaping (String) -> Bool,
        transformingValues transform: @escaping (String, Any) -> Any = { _, value in value }
    ) -> Snapshotting {
        let encoder = JSONEncoder()
        var snapshotting = SimplySnapshotting.lines.pullback { (encodable: Value) in
            let workingDictionary = try! JSONSerialization.jsonObject(
                with: encoder.encode(encodable),
                options: []
            ) as! [String: Any]

            let newDictionary = transformed(
                workingDictionary.recursivelyFiltered(includingKeysMatching: { !predicate($0) }),
                with: transform
            )
            let data = try! JSONSerialization.data(
                withJSONObject: newDictionary,
                options: [.sortedKeys, .prettyPrinted]
            )

            return String(
                data: data,
                encoding: .utf8
            )!
        }
        snapshotting.pathExtension = "json"
        return snapshotting
    }
}

private func transformed(_ value: Any, with transform: (String, Any) -> Any) -> Any {
    if let dictionary = value as? [String: Any] {
        return dictionary.reduce(into: [String: Any]()) { result, element in
            result[element.key] = transform(element.key, transformed(element.value, with: transform))
        }
    }

    if let array = value as? [Any] {
        return array.map { transformed($0, with: transform) }
    }

    return value
}
