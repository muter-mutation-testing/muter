import Foundation

typealias ReportOptions = (reporter: any Reporter, path: String?)

struct RunOptions {
    let reportOptions: ReportOptions
    let filesToMutate: [String]
    let skipCoverage: Bool
    let logger: Logger
    
    init(
        filesToMutate: [String],
        reportType: ReportType,
        reportURL: URL?,
        skipCoverage: Bool,
        logger: Logger
    ) {
        self.filesToMutate = filesToMutate
        self.skipCoverage = skipCoverage
        self.logger = logger
        self.reportOptions = ReportOptions(
            reporter: reportType.reporter,
            path: reportPath(reportURL)
        )
    }
}

private func reportPath(_ reportURL: URL?) -> String? {
    guard let reportURL = reportURL else {
        return nil
    }

    let absoluteString = reportURL.absoluteString
    if absoluteString.contains("/") {
        return absoluteString
    } else {
        return FileManager.default.currentDirectoryPath + "/" + absoluteString
    }
}

enum ReportType: String, CaseIterable {
    case plain, json, html, xcode
    
    static var description: String {
        allCases.map(\.rawValue).joined(separator: ", ")
    }
    
    var reporter: any Reporter {
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
