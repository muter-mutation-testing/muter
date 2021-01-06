import Foundation

final class HTMLReporter: Reporter {
    func mutationTestingFinished(mutationTestOutcomes outcomes: [MutationTestOutcome]) {
        print(report(from: outcomes))
    }

    func report(from outcomes: [MutationTestOutcome]) -> String {
        htmlReport(
            MuterTestReport(from: outcomes)
        )
    }
}

private func htmlReport(_ testReport: MuterTestReport) -> String {
    let head = """
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
    """

    let body = """
    <body>
        <div class="report">
            \(makeHeader(testReport))
            \(makeMain(testReport))
            \(makeFooter())
        </div>
    </body>
    """

    return """
    <!DOCTYPE html>
    <html lang="en">
    \(head)
    \(body)
    </html>
    """
}

private func makeHeader(
    _ testReport: MuterTestReport
) -> String {
    """
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
    """
}

private func makeMain(
    _ testReport: MuterTestReport
) -> String {
    return """
    <main>
        \(makeSummary(testReport))
        \(makeMutationsPerFileSection(testReport))
        \(makeAppliedMutationOperatorsSection(testReport))
    </main>
    """
}

private func makeFooter() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE, MMMM d yyyy HH:mm:ss"

    return """
    <footer>
        <div class="footer">\(formatter.string(from: .init()))</div>
    </footer>
    """
}

private func makeSummary(
    _ testReport: MuterTestReport
) -> String {
    """
    <div class="summary">
        <p>In total, Muter introduced <span class="strong">\(testReport.totalAppliedMutationOperators)</span> mutants in <span class="strong">\(testReport.fileReports.count)</span> files.</p>
    </div>
    """
}

private func makeMutationsPerFileSection(
    _ testReport: MuterTestReport
) -> String {
    """
    <div class="divider">
        <span class="divider-content">Mutation Operators per File</span>
    </div>
    <div class="mutation-operators-per-file">
        <div class="toggle">
            <input id="show-more-mutation-operators-per-file" type="checkbox" onclick="showHide(this, 'mutation-operators-per-file');" />
            <label for="show-more-mutation-operators-per-file">Show all</label>
        </div>
        \(makeMutationScoresTable(fileReports: testReport.fileReports))
    </div>
    """
}

private func makeAppliedMutationOperatorsSection(
    _ testReport: MuterTestReport
) -> String {
    """
    <div class="divider">
        <span class="divider-content">Applied Mutation Operators</span>
    </div>
    <div class="applied-operators">
        <div class="toggle">
            <input id="show-more-applied-operators" type="checkbox" onclick="showHide(this, 'applied-operators');" />
            <label for="show-more-applied-operators">Show all</label>
        </div>
        \(makeMutationOperatorsTable(fileReports: testReport.fileReports))
    </div>
    """
}

private func makeMutationOperatorsTable(
    fileReports: [MuterTestReport.FileReport]
) -> String {
    let thead =
        """
        <thead>
            <tr>
                <th>File</th>
                <th>Applied Mutation Operator</th>
                <th>Code Changes</th>
                <th>Mutation Test Result</th>
            </tr>
        </thead>
        """

    let tbody = fileReports.sorted().compactMap { report in
        report.appliedOperators.compactMap { appliedOperator in
            """
            <tr>
                <td>\(report.fileName):\(appliedOperator.mutationPoint.position.line)</td>
                <td>\(appliedOperator.mutationPoint.mutationOperatorId.rawValue)</td>
                <td>
                    <button onclick="showChange(this);">+</button>
                </td>
                <td>\(appliedOperator.testSuiteOutcome.asIcon)</td>
            </tr>
            <tr class="mutation-snapshot-before-row">
                <td class="mutation-snapshot-before" colspan="4">-  \(appliedOperator.mutationSnapshot.before)</td>
            </tr>
            <tr class="mutation-snapshot-after-row">
                <td class="mutation-snapshot-after" colspan="4">+  \(appliedOperator.mutationSnapshot.after)</td>
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

private func makeMutationScoresTable(
    fileReports: [MuterTestReport.FileReport]
) -> String {
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

    let tbody = fileReports.sorted().compactMap { report in
        """
        <tr>
          <td>\(report.fileName)</td>
          <td>\(report.appliedOperators.count)</td>
          <td style="color: \(report.scoreColor);">\(report.mutationScore)</td>
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

extension TestSuiteOutcome {
    var asIcon: String {
        switch (self) {
        case .passed:
            return """
                    <svg class="failed" role="img" viewBox="0 0 352 512">
                        <title>\(asMutationTestOutcome)</title>
                        <path d="M242.7 256l100.1-100.1c12.3-12.3 12.3-32.2 0-44.5l-22.2-22.2c-12.3-12.3-32.2-12.3-44.5 0L176 189.3 75.9 89.2c-12.3-12.3-32.2-12.3-44.5 0L9.2 111.5c-12.3 12.3-12.3 32.2 0 44.5L109.3 256 9.2 356.1c-12.3 12.3-12.3 32.2 0 44.5l22.2 22.2c12.3 12.3 32.2 12.3 44.5 0L176 322.7l100.1 100.1c12.3 12.3 32.2 12.3 44.5 0l22.2-22.2c12.3-12.3 12.3-32.2 0-44.5L242.7 256z" fill="currentColor"/>
                    </svg>
                    """
        case .failed, .runtimeError:
            return """
                    <svg class="passed" viewBox="0 0 512 512">
                        <title>\(asMutationTestOutcome)</title>
                        <path d="M173.9 439.4l-166.4-166.4c-10-10-10-26.2 0-36.2l36.2-36.2c10-10 26.2-10 36.2 0L192 312.7 432.1 72.6c10-10 26.2-10 36.2 0l36.2 36.2c10 10 10 26.2 0 36.2l-294.4 294.4c-10 10-26.2 10-36.2 0z" fill="currentColor"/>
                    </svg>
                    """
        case .buildError:
            return """
                    <svg class="build-error" viewBox="0 0 512 512">
                        <title>\(asMutationTestOutcome)</title>
                        <path d="M440.5 88.5l-52 52L415 167c9.4 9.4 9.4 24.6 0 33.9l-17.4 17.4c11.8 26.1 18.4 55.1 18.4 85.6 0 114.9-93.1 208-208 208S0 418.9 0 304 93.1 96 208 96c30.5 0 59.5 6.6 85.6 18.4L311 97c9.4-9.4 24.6-9.4 33.9 0l26.5 26.5 52-52 17.1 17zM500 60h-24c-6.6 0-12 5.4-12 12s5.4 12 12 12h24c6.6 0 12-5.4 12-12s-5.4-12-12-12zM440 0c-6.6 0-12 5.4-12 12v24c0 6.6 5.4 12 12 12s12-5.4 12-12V12c0-6.6-5.4-12-12-12zm33.9 55l17-17c4.7-4.7 4.7-12.3 0-17-4.7-4.7-12.3-4.7-17 0l-17 17c-4.7 4.7-4.7 12.3 0 17 4.8 4.7 12.4 4.7 17 0zm-67.8 0c4.7 4.7 12.3 4.7 17 0 4.7-4.7 4.7-12.3 0-17l-17-17c-4.7-4.7-12.3-4.7-17 0-4.7 4.7-4.7 12.3 0 17l17 17zm67.8 34c-4.7-4.7-12.3-4.7-17 0-4.7 4.7-4.7 12.3 0 17l17 17c4.7 4.7 12.3 4.7 17 0 4.7-4.7 4.7-12.3 0-17l-17-17zM112 272c0-35.3 28.7-64 64-64 8.8 0 16-7.2 16-16s-7.2-16-16-16c-52.9 0-96 43.1-96 96 0 8.8 7.2 16 16 16s16-7.2 16-16z"/>
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
