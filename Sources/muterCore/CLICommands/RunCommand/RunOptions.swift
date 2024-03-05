import Foundation

typealias ReportOptions = (reporter: Reporter, path: String?)

extension Run {
    struct Options {
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
                .flatMap(Run.Options.loadTestPlan)

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
}
extension Run.Options: Equatable {
    static func == (lhs: Run.Options, rhs: Run.Options) -> Bool {
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

extension Run.Options: Nullable {
    static var null: Run.Options {
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
