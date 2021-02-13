import Foundation

typealias Now = () -> Date

final class HTMLReporter: Reporter {
    private let now: Now

    init(now: @escaping Now = Date.init) {
        self.now = now
    }

    func mutationTestingFinished(mutationTestOutcome outcome: MutationTestOutcome) {
        print(report(from: outcome))
    }

    func report(from outcome: MutationTestOutcome) -> String {
        htmlReport(
            now,
            MuterTestReport(from: outcome)
        )
    }
}

private func htmlReport(
    _ now: Now,
    _ testReport: MuterTestReport
) -> String {
    let normalizeCSS = Bundle.resource(named: "normalize", ofType: "css")
    let reportCSS = Bundle.resource(named: "report", ofType: "css")
    let css = normalizeCSS + reportCSS

    let javascript = Bundle.resource(named: "javascript", ofType: "js")

    let muterLogo = Bundle.resource(named: "muterLogo", ofType: "svg")

    return """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="utf-8"/>
        <title>Muter Report</title>
        <style>
            \(css)
        </style>
        <script>
            \(javascript)
        </script>
    </head>
        <body>
            <div class="report">
                <header>
                    <div class="logo">
                        \(muterLogo)
                    </div>
                    <div class="header-item">
                        <div class="box" style="background-color: \(testReport.scoreColor);">
                            <p class="small">Mutation Score</p>
                            <h1>\(testReport.globalMutationScore)%</h1>
                        </div>
                    </div>
                    <div class="header-item">
                        <div class="box" style="background-color: #3498db;">
                            <p class="small">Operators Applied</p>
                            <h1>\(testReport.totalAppliedMutationOperators)</h1>
                        </div>
                    </div>
                </header>
                <main>
                    <div class="summary">
                        <p>In total, Muter introduced
                            <span class="strong">\(testReport.totalAppliedMutationOperators)</span> mutants in
                            <span class="strong">\(testReport.fileReports.count)</span> files.
                        </p>
                    </div>
                    <div class="divider">
                        <span class="divider-content">Mutation Operators per File</span>
                    </div>
                    <div class="mutation-operators-per-file">
                        <div class="toggle">
                            <input id="show-more-mutation-operators-per-file" type="checkbox" onclick="showHide(this.checked, 'mutation-operators-per-file');" />
                            <label for="show-more-mutation-operators-per-file">Show all</label>
                        </div>
                        \(testReport.fileReports.scoreHTMLTable())
                    </div>
                    <div class="divider">
                        <span class="divider-content">Applied Mutation Operators</span>
                    </div>
                    <div class="applied-operators">
                        <div class="toggle">
                            <input id="show-more-applied-operators" type="checkbox" onclick="showHide(this.checked, 'applied-operators');" />
                            <label for="show-more-applied-operators">Show all</label>
                        </div>
                        \(testReport.fileReports.operatorsHTMLTable())
                    </div>
                </main>
                <footer>
                    <div class="footer">\(now().string)</div>
                </footer>
            </div>
        </body>
    </html>
    """
}

private extension Date {
    var string: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d yyyy HH:mm:ss"

        return formatter.string(from: self)
    }
}

private extension Array where Element == MuterTestReport.FileReport {
    func scoreHTMLTable() -> String {
        let thead =
            """
            <thead>
                <tr>
                    <th>File</th>
                    <th># of Introduced Mutants</th>
                    <th>Mutation Score</th>
                </tr>
            </thead>
            """

        let tbody = sorted().compactMap { report in
            """
            <tr>
              <td class="left-aligned">\(report.fileName)</td>
              <td class="right-aligned">\(report.appliedOperators.count)</td>
              <td class="right-aligned" style="color: \(report.scoreColor);">\(report.mutationScore)</td>
            </tr>
            """
        }.joined(separator: "\n")

        return """
        <table id="mutation-operators-per-file">
            \(thead)
            <tbody>
            \(tbody)
            </tbody>
        </table>
        """
    }

    func operatorsHTMLTable() -> String {
        let thead =
            """
            <thead>
                <tr>
                    <th>File</th>
                    <th>Applied Mutation Operator</th>
                    <th>Changes</th>
                    <th>Mutation Test Result</th>
                </tr>
            </thead>
            """

        let tbody = sorted().compactMap { report in
            report.appliedOperators.compactMap { appliedOperator in
                """
                <tr>
                    <td class="left-aligned">\(report.fileName):\(appliedOperator.mutationPoint.position.line)</td>
                    <td class="left-aligned"><wbr>\(appliedOperator.mutationPoint.mutationOperatorId.friendlyName)<wbr></td>
                    <td class="mutation-snapshot">\(appliedOperator.diff)</td>
                    <td>\(appliedOperator.testSuiteOutcome.asIcon)</td>
                </tr>
                """
            }.joined(separator: "\n")
        }.joined(separator: "\n")

        return """
        <table id="applied-operators">
            \(thead)
            <tbody>
            \(tbody)
            </tbody>
        </table>
        """
    }
}

private extension MutationOperator.Id {
    var friendlyName: String {
        switch self {
        case .ror: return "Relational Operator Replacement"
        case .removeSideEffects: return "Remove Side Effects"
        case .logicalOperator: return "Change Logical Connector"
        }
    }
}

private extension MuterTestReport.AppliedMutationOperator {
    var diff: String {
        let diff: String
        if mutationPoint.mutationOperatorId == .removeSideEffects {
            diff = """
            <span class="snapshot-before">\(mutationSnapshot.before)</span>
            """
        } else {
            diff = """
            <span class="snapshot-before">\(mutationSnapshot.before)</span>
            <span class="snapshot-arrow">→</span>
            <span class="snapshot-after">\(mutationSnapshot.after)</span>
            """
        }

        return """
        <div class="snapshot-changes">
            \(diff)
        </div>
        """
    }
}

private extension TestSuiteOutcome {
    var asIcon: String {
        let icon: String
        switch self {
        case .passed:
            icon = Bundle.resource(
                named: "testPassed",
                ofType: "svg"
            )
        case .failed, .runtimeError:
            icon = Bundle.resource(
                named: "testFailed",
                ofType: "svg"
            )
        case .buildError:
            icon = Bundle.resource(
                named: "testBuildError",
                ofType: "svg"
            )
        }
        
        return icon.replacingOccurrences(of: "$title$", with: asMutationTestOutcome)
    }
}

private extension MuterTestReport.FileReport {
    var scoreColor: String { coloredMutationScore(for: mutationScore) }
}

private extension MuterTestReport {
    var scoreColor: String { coloredMutationScore(for: globalMutationScore) }
}

private func coloredMutationScore(for score: Int) -> String {
    switch score {
    case 0...25: return "#f70000"
    case 26...50: return "#ce9400"
    case 51...75: return "#92b300"
    default: return "#51a100"
    }
}
