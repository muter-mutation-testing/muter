@testable import muterCore

extension SourceCodeInfo {
    public var asSourceFileInfo: SourceFileInfo {
        .init(
            path: path,
            source: code.description
        )
    }
}
