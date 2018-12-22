import Foundation

public extension URL {
    func withoutScheme() -> URL {
        let urlWithoutScheme = String(
            pathComponents
                .joined(separator: "/")
                .dropFirst()
        )

        return URL(string: urlWithoutScheme)!
    }
}
