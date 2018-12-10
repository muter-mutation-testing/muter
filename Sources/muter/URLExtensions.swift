import Foundation

extension URL {
    func withoutScheme() -> URL {
        
        let urlWithoutScheme = String(
            self.pathComponents
                .joined(separator: "/")
                .dropFirst()
        )
        
        return URL(string: urlWithoutScheme)!
    }
}
