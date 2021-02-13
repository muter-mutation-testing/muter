import Foundation

protocol Nullable: Equatable {
    static var null: Self { get }
}

extension Array where Element: Nullable {
    func ignoringNulls() -> [Element] {
        exclude { $0 == .null }
    }
}
