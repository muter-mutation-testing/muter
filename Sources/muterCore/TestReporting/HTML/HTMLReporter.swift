import Foundation
import Plot

final class HTMLReporter: Reporter {
    @Dependency(\.now)
    private var now: Now

    func report(from outcome: MutationTestOutcome) -> String {
        htmlReport(
            outcome,
            now
        )
    }
}

private func htmlReport(
    _ outcome: MutationTestOutcome,
    _ now: Now
) -> String {
    let testReport = MuterTestReport(from: outcome)

    return HTML(
        .lang(.english),
        .muterHeader(),
        .body(
            .div(
                .themeToggle(),
                .class("report"),
                .muterHeader(from: testReport),
                .main(
                    .class("summary"),
                    .summary(
                        from: testReport,
                        newVersion: outcome.newVersion
                    ),
                    .divider("Mutation Operators per File"),
                    .mutationOperatorsPerFile(from: testReport),
                    .divider("Applied Mutation Operators"),
                    .appliedOperators(from: testReport)
                ),
                .muterFooter(now: now)
            )
        )
    ).render()
}

private extension Date {
    var string: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d yyyy HH:mm:ss"

        return formatter.string(from: self)
    }
}

extension Node where Context == HTML.DocumentContext {
    static func muterHeader() -> Self {
        let normalizeCSS = normalize
        let reportCSS = css
        let css = normalizeCSS + reportCSS

        return .head(
            .title("Muter Report"),
            .meta(.charset(.utf8)),
            .style(css),
            .raw("<script>\(javascript)</script>")
        )
    }
}

extension Node where Context: HTML.BodyContext {
    static func muterHeader(from testReport: MuterTestReport) -> Self {
        .header(
            .div(.class("logo"), .raw(muterLogo)),
            .div(
                .class("header-item"),
                .div(
                    .class("box"),
                    .style("background-color: \(testReport.scoreColor)"),
                    .p(.class("small"), "Mutation Score"),
                    .h1("\(testReport.globalMutationScore)%")
                )
            ),
            .unwrap(testReport.projectCodeCoverage) { coverage in
                .div(
                    .class("header-item"),
                    .div(
                        .class("box"),
                        .style("background-color: \(coloredMutationScore(for: coverage))"),
                        .p(.class("small"), "Code Coverage"),
                        .h1("\(coverage)%")
                    )
                )
            },
            .div(
                .class("header-item"),
                .div(
                    .class("box"),
                    .style("background-color: #3498db"),
                    .p(.class("small"), "Operators Applied"),
                    .h1("\(testReport.totalAppliedMutationOperators)")
                )
            )
        )
    }
    
    static func themeToggle() -> Self {
        .div(
            .button(.id("theme-toggle"), .class("theme-toggle"))
        )
    }

    static func summary(
        from testReport: MuterTestReport,
        newVersion: String
    ) -> Self {
        .div(
            .p(
                "📝 In total, Muter introduced ",
                .span(.class("strong"), "\(testReport.totalAppliedMutationOperators)"),
                " mutants in ",
                .span(.class("strong"), "\(testReport.fileReports.count)"),
                " files."
            ),
            .p("⏰ Muter took \(testReport.timeElapsed) to run."),
            .if(
                !newVersion.isEmpty,
                .p("🆕 The version \(newVersion) of Muter is available")
            )
        )
    }

    static func divider(_ title: String) -> Self {
        .div(
            .class("divider"),
            .span(.class("divider-content"), "\(title)")
        )
    }

    static func mutationOperatorsPerFile(from testReport: MuterTestReport) -> Self {
        .div(
            .class("mutation-operators-per-file"),
            .div(
                .class("toggle"),
                .input(
                    .id("show-more-mutation-operators-per-file"),
                    .type(.checkbox),
                    .attribute(named: "onclick", value: "showHide(this.checked, 'mutation-operators-per-file');")
                ),
                .label(.for("show-more-mutation-operators-per-file"), "Show all")
            ),
            .mutationScoreTable(from: testReport.fileReports)
        )
    }

    static func mutationScoreTable(from fileReports: [MuterTestReport.FileReport]) -> Self {
        .table(
            .id("mutation-operators-per-file"),
            .thead(
                .tr(
                    .th("File"),
                    .th("# of Introduced Mutants"),
                    .th("Mutation Score")
                )
            ),
            .tbody(
                .forEach(fileReports.sorted()) { report in
                    .tr(
                        .td(.class("left-aligned"), "\(report.fileName)"),
                        .td(.class("right-aligned"), "\(report.appliedOperators.count)"),
                        .td(.class("right-aligned"), .style("color: \(report.scoreColor)"), "\(report.mutationScore)")
                    )
                }
            )
        )
    }

    static func appliedOperators(from testReport: MuterTestReport) -> Self {
        .div(
            .class("applied-operators"),
            .div(
                .class("toggle"),
                .input(
                    .id("show-more-applied-operators"),
                    .type(.checkbox),
                    .attribute(named: "onclick", value: "showHide(this.checked, 'applied-operators');")
                ),
                .label(.for("show-more-applied-operators"), "Show all")
            ),
            .appliedOperatorsTable(from: testReport.fileReports)
        )
    }

    static func appliedOperatorsTable(from fileReports: [MuterTestReport.FileReport]) -> Self {
        let reports = fileReports.sorted().flatMap { report in
            report.appliedOperators.compactMap { appliedOperator in
                (fileName: report.fileName, appliedOperator: appliedOperator)
            }
        }

        return .table(
            .id("applied-operators"),
            .thead(
                .tr(
                    .th("File"),
                    .th("Applied Mutation Operator"),
                    .th("Changes"),
                    .th("Mutation Test Result")
                )
            ),
            .tbody(
                .forEach(reports) { report -> Node<HTML.TableContext> in
                    .tr(
                        .td(
                            .class("left-aligned"),
                            "\(report.fileName):\(report.appliedOperator.mutationPoint.position.line)"
                        ),
                        .td(
                            .class("left-aligned"),
                            .raw("<wbr>\(report.appliedOperator.mutationPoint.mutationOperatorId.friendlyName)<wbr>")
                        ),
                        .td(.class("mutation-snapshot"), .diff(of: report.appliedOperator)),
                        .td(
                            .raw("\(report.appliedOperator.testSuiteOutcome.asIcon)")
                        )
                    )
                }
            )
        )
    }

    static func diff(of appliedOperator: MuterTestReport.AppliedMutationOperator) -> Self {
        .div(
            .class("snapshot-changes"),
            .if(
                appliedOperator.testSuiteOutcome == .noCoverage,
                .span(
                    .class("snapshot-no-coverage"),
                    ""
                ),
                else:
                .if(
                    appliedOperator.mutationPoint.mutationOperatorId == .removeSideEffects,
                    .span(
                        .class("snapshot-before"),
                        "\(appliedOperator.mutationSnapshot.before)"
                    ),
                    else:
                    .group(
                        .span(.class("snapshot-before"), "\(appliedOperator.mutationSnapshot.before)"),
                        .span(.class("snapshot-arrow"), "\u{2192}"), // →
                        .span(.class("snapshot-after"), "\(appliedOperator.mutationSnapshot.after)")
                    )
                )
            )
        )
    }

    static func muterFooter(now: () -> Date) -> Self {
        .footer(
            .class("footer"),
            "\(now().string)"
        )
    }
}

private extension MutationOperator.Id {
    var friendlyName: String {
        switch self {
        case .ror: "Relational Operator Replacement"
        case .removeSideEffects: "Remove Side Effects"
        case .logicalOperator: "Change Logical Connector"
        case .swapTernary: "Swap Ternary"
        }
    }
}

private extension TestSuiteOutcome {
    // icons are from the collection: https://www.svgrepo.com/collection/openmoji-vectors/
    var asIcon: String {
        let icon: String
        switch self {
        case .passed:
            icon = testPassed
        case .failed,
             .runtimeError:
            icon = testFailed
        case .buildError:
            icon = testBuildError
        case .noCoverage:
            icon = skipped
        case .timeout:
            icon = testTimeout
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
    case 0 ... 25: "#f70000"
    case 26 ... 50: "#ce9400"
    case 51 ... 75: "#92b300"
    default: "#51a100"
    }
}
