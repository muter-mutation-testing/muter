import SwiftFormat

public func formatCode(_ code: String) -> String {
    code
}

private class OutputStream: TextOutputStream {
    private(set) var output: String = ""

    func write(_ string: String) {
        output += string
    }
}
