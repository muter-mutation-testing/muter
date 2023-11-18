import Foundation

typealias ReportOptions = (reporter: Reporter, path: String?)

struct RunOptions {
    let reportOptions: ReportOptions
    let filesToMutate: [String]
    let mutationOperatorsList: MutationOperatorList
    let skipCoverage: Bool
    let skipUpdateCheck: Bool
    let configurationURL: URL?

    init(
        filesToMutate: [String],
        reportFormat: ReportFormat,
        reportURL: URL?,
        mutationOperatorsList: MutationOperatorList,
        skipCoverage: Bool,
        skipUpdateCheck: Bool,
        configurationURL: URL?
    ) {
        self.filesToMutate = filesToMutate
        self.skipCoverage = skipCoverage
        self.mutationOperatorsList = mutationOperatorsList
        self.skipUpdateCheck = skipUpdateCheck
        self.configurationURL = configurationURL

        reportOptions = ReportOptions(
            reporter: reportFormat.reporter,
            path: reportPath(reportURL)
        )
    }
}

extension RunOptions: Equatable {
    static func == (lhs: RunOptions, rhs: RunOptions) -> Bool {
        lhs.filesToMutate == rhs.filesToMutate &&
            lhs.mutationOperatorsList == rhs.mutationOperatorsList &&
            lhs.skipCoverage == rhs.skipCoverage &&
            lhs.skipUpdateCheck == rhs.skipUpdateCheck &&
            lhs.configurationURL == rhs.configurationURL &&
            lhs.reportOptions.path == rhs.reportOptions.path &&
            "\(lhs.reportOptions.reporter)" == "\(rhs.reportOptions.reporter)"
    }
}

extension RunOptions: Nullable {
    static var null: RunOptions {
        .init(
            filesToMutate: [],
            reportFormat: .plain,
            reportURL: nil,
            mutationOperatorsList: [],
            skipCoverage: false,
            skipUpdateCheck: false,
            configurationURL: nil
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
