import Foundation

extension Bundle {
    static func resource(named: String, ofType type: String) -> String {
        Bundle.module.path(forResource: named, ofType: type)
            .flatMap {
                try? String(contentsOfFile: $0)
            } ?? ""
    }
}
