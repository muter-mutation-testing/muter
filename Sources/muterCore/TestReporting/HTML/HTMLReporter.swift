import Foundation
import Plot

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
            MuterTestReport(from: outcomes),
            now
        )
    }
}

private func htmlReport(
    _ testReport: MuterTestReport,
    _ now: Now
) -> String {
    HTML(
        .muterHeader(),
        .body(
            .div(
                .class("report"),
                .muterHeader(from: testReport),
                .main(
                    .class("summary"),
                    .summary(from: testReport),
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
        let normalizeCSS = Bundle.resource(named: "normalize", ofType: "css")
        let reportCSS = Bundle.resource(named: "report", ofType: "css")
        let css = normalizeCSS + reportCSS
        
        let javascript = Bundle.resource(named: "javascript", ofType: "js")
        
        return .head(
            .attribute(named: "charset", value: "utf-8"),
            .title("Muter Report"),
            .style(css),
            .raw("<script>\(javascript)</script>")
        )
    }
}

extension Node where Context: HTML.BodyContext {
    static func muterHeader(from testReport: MuterTestReport) -> Self {
        let muterLogo = Bundle.resource(named: "muterLogo", ofType: "svg")
        
        return .header(
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
    
    static func summary(from testReport: MuterTestReport) -> Self {
        .p(
            "In total, Muter introduced ",
            .span(.class("strong"), "\(testReport.totalAppliedMutationOperators)"),
            " mutants in ",
            .span(.class("strong"), "\(testReport.fileReports.count)"),
            " files."
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
                    .id("show-more-mutation-operators-per-file"),
                    .type(.checkbox),
                    .attribute(named: "onclick", value: "showHide(this.checked, 'mutation-operators-per-file');")
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
                        .td(.class("left-aligned"), "\(report.fileName):\(report.appliedOperator.mutationPoint.position.line)"),
                        .td(.class("left-aligned"), .raw("<wbr>\(report.appliedOperator.mutationPoint.mutationOperatorId.friendlyName)<wbr>")),
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
            .if(appliedOperator.mutationPoint.mutationOperatorId == .removeSideEffects,
                .span(
                    .class("snapshot-before"),
                    "\(appliedOperator.mutationSnapshot.before)"
                ),
                else:
                    .group(
                        .span(.class("snapshot-before"), "\(appliedOperator.mutationSnapshot.before)"),
                        .span(.class("snapshot-arrow"), "→"),
                        .span(.class("snapshot-after"), "\(appliedOperator.mutationSnapshot.after)")
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
        case .ror: return "Relational Operator Replacement"
        case .removeSideEffects: return "Remove Side Effects"
        case .logicalOperator: return "Change Logical Connector"
        }
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
