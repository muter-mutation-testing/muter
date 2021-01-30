import Foundation

typealias Now = () -> Date

final class HTMLReporter: Reporter {
    private let now: Now

    init(now: @escaping Now = Date.init) {
        self.now = now
    }

    func mutationTestingFinished(mutationTestOutcomes outcomes: [MutationTestOutcome]) {
        print(report(from: outcomes))
    }

    func report(from outcomes: [MutationTestOutcome]) -> String {
        htmlReport(
            now,
            MuterTestReport(from: outcomes)
        )
    }
}

private func htmlReport(
    _ now: Now,
    _ testReport: MuterTestReport
) -> String {
    """
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
        <table id=\"mutation-operators-per-file\">
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
        <table id=\"applied-operators\">
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
        var diff = ""
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
        switch (self) {
        case .passed:
            return """
                    <svg class="failed" role="img" viewBox="0 0 72 72">
                        <title>\(asMutationTestOutcome)</title>
                        <path fill="#ea5a47" d="M58.14 21.78l-7.76-8.013-14.29 14.22-14.22-14.22-8.013 8.013L28.217 36l-14.36 14.22 8.014 8.013 14.22-14.22 14.29 14.22 7.76-8.013L43.921 36z"/>
                        <path fill="none" stroke="#000" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2" d="M58.14 21.78l-7.76-8.013-14.29 14.22-14.22-14.22-8.013 8.013L28.207 36l-14.35 14.22 8.014 8.013 14.22-14.22 14.29 14.22 7.76-8.013L43.921 36z"/>
                    </svg>
                    """
        case .failed, .runtimeError:
            return """
                    <svg class="passed" role="img" viewBox="0 0 72 72">
                        <title>\(asMutationTestOutcome)</title>
                        <path fill="#b1cc33" d="m61.5 23.3-8.013-8.013-25.71 25.71-9.26-9.26-8.013 8.013 17.42 17.44z"/>
                        <path fill="none" stroke="#000" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2" d="M10.5 39.76L27.92 57.2 61.5 23.31l-8.013-8.013-25.71 25.71-9.26-9.26z"/>
                    </svg>
                    """
        case .buildError:
            return """
                    <svg class="build-error" role="img" viewBox="0 0 72 72">
                        <title>\(asMutationTestOutcome)</title>
                        <path fill="#FFF" d="M40.526 16.92a14.934 14.934 0 00-4.336-.645h-.03a15.731 15.731 0 00-3.121.324 15.412 15.412 0 00-9.095 5.832 17.022 17.022 0 00-3.267 7.59 17.404 17.404 0 004.02 14.42l.112.126c.884.996 2.094 2.362 2.094 3.814l-.019 4.178a.838.838 0 01-.837.837 25.063 25.063 0 005.873 2.124c3.192.72 6.514.629 9.662-.263 2.693-12.712 1.982-25.99-1.056-38.337z"/>
                        <path fill="#D0CFCE" d="M46.98 20.812a15.5 15.5 0 00-6.454-3.893c3.038 12.348 3.75 25.626 1.054 38.332a22.514 22.514 0 004.69-1.902.846.846 0 01-.85-.825l-.057-4.14c0-1.383 1.173-2.673 2.028-3.616.121-.134.237-.26.34-.38 5.907-6.861 5.583-17.1-.746-23.575h-.005z"/>
                        <path fill="#3F3F3F" d="M29.37 35.24a4 4 0 100 8 4 4 0 000-8zM43.062 35.24a4 4 0 100 8 4 4 0 000-8z"/>
                        <path fill="#FFF" d="M53.015 20.665a460.015 460.015 0 012.416-2.39s1.943 1.84 3.27 1.443c1.373-.41 2.156-1.808 2.035-2.954-.167-1.588-2.11-3.04-4.438-2.556.406-1.513.068-3.062-.933-3.995-1.654-1.54-4.078-.479-4.99.918-1.22 1.869 1.574 3.663 1.574 3.663a410.45 410.45 0 00-2.177 2.151M19.678 46.908c-1.549 1.54-2.6 2.58-2.92 2.89-.655-1.302-2.132-1.943-3.458-1.546-1.374.411-2.157 1.808-2.036 2.954.168 1.589 2.11 3.04 4.438 2.556-.405 1.513-.068 3.062.933 3.995 1.654 1.54 4.33.614 4.99-.918.47-1.088.193-2.297-1.438-3.505.26-.252 1.005-.99 2.11-2.087M19.113 20.792a489.893 489.893 0 00-2.543-2.516s-1.944 1.839-3.27 1.442c-1.374-.411-2.157-1.808-2.036-2.954.168-1.589 2.11-3.04 4.438-2.556-.405-1.513-.068-3.062.933-3.995 1.654-1.54 4.078-.479 4.99.918 1.22 1.869-1.573 3.663-1.573 3.663.286.277 1.157 1.14 2.447 2.421M52.497 47.082a535.186 535.186 0 002.744 2.716c.655-1.302 2.133-1.943 3.459-1.546 1.374.411 2.157 1.808 2.036 2.954-.168 1.589-2.11 3.04-4.438 2.556.405 1.513.068 3.062-.933 3.995-1.654 1.54-4.33.614-4.99-.918-.47-1.088-.193-2.297 1.438-3.505-.258-.25-.991-.975-2.078-2.055"/>
                        <g fill="none" stroke="#000" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M46.255 52.473l-.058-4.14c0-1.215 1.381-2.543 2.161-3.435A18.046 18.046 0 0052.79 32.97c0-9.716-7.45-17.594-16.63-17.575a16.518 16.518 0 00-3.288.341c-6.608 1.355-11.874 7.083-13.022 14.106a18.22 18.22 0 004.224 15.11c.768.87 1.995 2.195 1.995 3.385l-.018 4.173M29.371 51.081v4.004M34.157 51.973v4.005M43.063 51.081v4.004M38.72 51.973v4.005"/>
                        <path stroke-linecap="round" stroke-linejoin="round" d="M33.702 48.742l2.456-4.899 2.936 4.899"/>
                        <circle cx="29.371" cy="39.2" r="4.188" stroke-miterlimit="10"/>
                        <circle cx="43.063" cy="39.2" r="4.188" stroke-miterlimit="10"/>
                        <path stroke-linecap="round" stroke-linejoin="round" d="M53.015 20.665a460.015 460.015 0 012.416-2.39s1.943 1.84 3.27 1.443c1.373-.41 2.156-1.808 2.035-2.954-.167-1.588-2.11-3.04-4.438-2.556.406-1.513.068-3.062-.933-3.995-1.654-1.54-4.078-.479-4.99.918-1.22 1.869 1.574 3.663 1.574 3.663a410.45 410.45 0 00-2.177 2.151M19.678 46.908c-1.549 1.54-2.6 2.58-2.92 2.89-.655-1.302-2.132-1.943-3.458-1.546-1.374.411-2.157 1.808-2.036 2.954.168 1.589 2.11 3.04 4.438 2.556-.405 1.513-.068 3.062.933 3.995 1.654 1.54 4.33.614 4.99-.918.47-1.088.193-2.297-1.438-3.505.26-.252 1.005-.99 2.11-2.087M19.113 20.792a489.893 489.893 0 00-2.543-2.516s-1.944 1.839-3.27 1.442c-1.374-.411-2.157-1.808-2.036-2.954.168-1.589 2.11-3.04 4.438-2.556-.405-1.513-.068-3.062.933-3.995 1.654-1.54 4.078-.479 4.99.918 1.22 1.869-1.573 3.663-1.573 3.663.286.277 1.157 1.14 2.447 2.421M52.497 47.082a535.186 535.186 0 002.744 2.716c.655-1.302 2.133-1.943 3.459-1.546 1.374.411 2.157 1.808 2.036 2.954-.168 1.589-2.11 3.04-4.438 2.556.405 1.513.068 3.062-.933 3.995-1.654 1.54-4.33.614-4.99-.918-.47-1.088-.193-2.297 1.438-3.505-.258-.25-.991-.975-2.078-2.055"/>
                      </g>
                    </svg>
                    """
        }
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
