import Foundation

public extension URL {
    func withoutScheme() -> String {
        let urlWithoutScheme = String(
            pathComponents
                .joined(separator: "/")
                .dropFirst()
        )

        return urlWithoutScheme
    }
}
