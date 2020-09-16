import SnapshotTesting
import Foundation

extension Snapshotting where Value: Encodable, Format == String {
    static func json(excludingKeysMatching predicate: @escaping (String) -> Bool) -> Snapshotting {
        
        let encoder = JSONEncoder()
        var snapshotting = SimplySnapshotting.lines.pullback { (encodable: Value) in
            let workingDictionary = try! JSONSerialization.jsonObject(with: encoder.encode(encodable), options: []) as! [String: Any]
            let newDictionary = workingDictionary.recursivelyFiltered(includingKeysMatching: { !predicate($0) })
            let data = try! JSONSerialization.data(withJSONObject: newDictionary, options: [.sortedKeys, .prettyPrinted])
            return String(data: data, encoding: .utf8)!
        }
        snapshotting.pathExtension = "json"
        return snapshotting
    }
}
