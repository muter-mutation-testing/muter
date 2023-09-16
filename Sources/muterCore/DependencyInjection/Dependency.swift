import Foundation

@propertyWrapper
struct Dependency<T> {
    private var dependency: (World) -> T
    var wrappedValue: T {
        get { dependency(current) }
        set {}
    }

    init(_ keyPath: KeyPath<World, T>) {
        dependency = { $0[keyPath: keyPath] }
    }
}
