@testable import muterCore

extension SourceCodeInfo {
    public var asSourceFileInfo: SourceFileInfo {
        .init(
            file: path,
            source: code.description
        )
    }
}
