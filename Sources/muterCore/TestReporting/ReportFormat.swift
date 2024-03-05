import Foundation

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
