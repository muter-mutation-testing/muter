import Foundation

typealias ReportOptions = (reporter: Reporter, path: String?)

struct RunOptions {
    let reportOptions: ReportOptions
    let filesToMutate: [String]
    let mutationOperatorsList: MutationOperatorList
    let skipCoverage: Bool
    let skipUpdateCheck: Bool
    let configurationURL: URL?
    let projectMappings: ProjectSchemataMappings?
    let generateMappings: Bool

    var isUsingMappingsJson: Bool {
        projectMappings != nil
    }

    init(
        filesToMutate: [String],
        reportFormat: ReportFormat,
        reportURL: URL?,
        mutationOperatorsList: MutationOperatorList,
        skipCoverage: Bool,
        skipUpdateCheck: Bool,
        configurationURL: URL?,
        mappingsJsonURL: URL?,
        generateMappings: Bool
    ) {
        self.skipCoverage = skipCoverage
        self.skipUpdateCheck = skipUpdateCheck
        self.generateMappings = generateMappings
        self.mutationOperatorsList = mutationOperatorsList
        self.configurationURL = configurationURL
        self.projectMappings = mappingsJsonURL
            .map(\.path)
            .flatMap(RunOptions.loadMappingsJson)

        self.filesToMutate = filesToMutate.reduce(into: []) { accum, next in
            accum.append(
                contentsOf: next.components(separatedBy: ",")
                    .exclude { $0.isEmpty }
            )
        }

        self.reportOptions = ReportOptions(
            reporter: reportFormat.reporter,
            path: reportURL?.path
        )
    }

    static func loadMappingsJson(atPath path: String) -> ProjectSchemataMappings? {
        current.fileManager.contents(atPath: path)
            .flatMap {
                try? JSONDecoder().decode(ProjectSchemataMappings.self, from: $0)
            }
    }
}

extension RunOptions: Equatable {
    static func == (lhs: RunOptions, rhs: RunOptions) -> Bool {
        lhs.filesToMutate == rhs.filesToMutate &&
            lhs.mutationOperatorsList == rhs.mutationOperatorsList &&
            lhs.skipCoverage == rhs.skipCoverage &&
            lhs.skipUpdateCheck == rhs.skipUpdateCheck &&
            lhs.configurationURL == rhs.configurationURL &&
            lhs.projectMappings == rhs.projectMappings &&
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
            configurationURL: nil,
            mappingsJsonURL: nil,
            generateMappings: false
        )
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
