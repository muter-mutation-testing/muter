import Foundation

extension Collection {
    func map<Value>(_ keyPath: KeyPath<Element, Value>) -> [Value] {
        return map { $0[keyPath: keyPath] }
    }
}

extension Optional {
    func map<Value>(_ keyPath: KeyPath<Wrapped, Value>) -> Value? {
        return map { $0[keyPath: keyPath] }
    }
}
