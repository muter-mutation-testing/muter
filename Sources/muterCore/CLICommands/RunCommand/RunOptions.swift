import Foundation

typealias ReportOptions = (reporter: Reporter, path: String?)

struct RunOptions {
    let reportOptions: ReportOptions
    let filesToMutate: [String]
    let skipCoverage: Bool

    @Dependency(\.logger)
    private var logger: Logger

    init(
        filesToMutate: [String],
        reportFormat: ReportFormat,
        reportURL: URL?,
        skipCoverage: Bool
    ) {
        self.filesToMutate = filesToMutate
        self.skipCoverage = skipCoverage
        reportOptions = ReportOptions(
            reporter: reportFormat.reporter,
            path: reportPath(reportURL)
        )
    }
}

private func reportPath(_ reportURL: URL?) -> String? {
    guard let reportURL else {
        return nil
    }

    let absoluteString = reportURL.absoluteString
    if absoluteString.contains("/") {
        return absoluteString
    } else {
        return FileManager.default.currentDirectoryPath + "/" + absoluteString
    }
}

enum ReportFormat: String, CaseIterable {
    case plain
    case json
    case html
    case xcode

    static var description: String {
        allCases.map(\.rawValue).joined(separator: ", ")
    }

    var reporter: Reporter {
        switch self {
        case .plain:
            return PlainTextReporter()
        case .json:
            return JsonReporter()
        case .html:
            return HTMLReporter()
        case .xcode:
            return XcodeReporter()
        }
    }
}
