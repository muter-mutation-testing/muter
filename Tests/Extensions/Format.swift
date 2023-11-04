import SwiftFormat

public func formatCode(_ code: String) -> String {
    let formatter = SwiftFormatter(configuration: Configuration())
    var stream = OutputStream()
    try? formatter.format(source: code, assumingFileURL: nil, to: &stream)

    return stream.output
}

private class OutputStream: TextOutputStream {
    private(set) var output: String = ""

    func write(_ string: String) {
        output += string
    }
}
