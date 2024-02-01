import SwiftFormat

public func formatCode(_ code: String) -> String {
    var configuration = Configuration()
    configuration.indentation = .spaces(4)
    let formatter = SwiftFormatter(configuration: configuration)
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
