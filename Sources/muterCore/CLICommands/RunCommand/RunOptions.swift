import Foundation

typealias ReportOptions = (reporter: Reporter, path: String?)

struct RunOptions {
    let reportOptions: ReportOptions
    let filesToMutate: [String]
    let mutationOperatorsList: MutationOperatorList
    let skipCoverage: Bool
    let skipUpdateCheck: Bool
    let configurationURL: URL?
    let testPlan: MuterTestPlan?
    let createTestPlan: Bool

    var isUsingTestPlan: Bool {
        testPlan != nil
    }

    init(
        filesToMutate: [String] = [],
        reportFormat: ReportFormat = .plain,
        reportURL: URL? = nil,
        mutationOperatorsList: MutationOperatorList = [],
        skipCoverage: Bool,
        skipUpdateCheck: Bool,
        configurationURL: URL?,
        testPlanURL: URL? = nil,
        createTestPlan: Bool = false
    ) {
        self.skipCoverage = skipCoverage
        self.skipUpdateCheck = skipUpdateCheck
        self.createTestPlan = createTestPlan
        self.mutationOperatorsList = mutationOperatorsList
        self.configurationURL = configurationURL
        testPlan = testPlanURL
            .map(\.path)
            .flatMap(RunOptions.loadTestPlan)

        self.filesToMutate = filesToMutate.reduce(into: []) { accum, next in
            accum.append(
                contentsOf: next.components(separatedBy: ",")
                    .exclude { $0.isEmpty }
            )
        }

        reportOptions = ReportOptions(
            reporter: reportFormat.reporter,
            path: reportURL?.path
        )
    }

    static func loadTestPlan(atPath path: String) -> MuterTestPlan? {
        current.fileManager.contents(atPath: path)
            .flatMap {
                try? JSONDecoder().decode(MuterTestPlan.self, from: $0)
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
            lhs.testPlan == rhs.testPlan &&
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
            testPlanURL: nil,
            createTestPlan: false
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
