import Foundation

/// A report in the mutation testing report schema of Stryker, version 2:
/// https://github.com/stryker-mutator/mutation-testing-elements/tree/master/packages/report-schema
///
/// Tools that read this schema can show Muter's results, for example the `mutation-testing-elements`
/// HTML report and the Stryker Dashboard.
final class StrykerReporter: Reporter {
    /// Reads the source of a file in the original project. The report includes the full source of
    /// each mutated file, so the tools can show the mutants in their code.
    private let readFile: (String) -> String?

    init(
        readFile: @escaping (String) -> String? = { try? String(contentsOfFile: $0, encoding: .utf8) }
    ) {
        self.readFile = readFile
    }

    func report(from outcome: MutationTestOutcome) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]

        guard let encoded = try? encoder.encode(StrykerReport(outcome: outcome, readFile: readFile)),
              let json = String(data: encoded, encoding: .utf8)
        else {
            return ""
        }

        return json
    }
}

struct StrykerReport: Encodable, Equatable {
    struct Thresholds: Encodable, Equatable {
        let high: Int
        let low: Int
    }

    struct Framework: Encodable, Equatable {
        struct Branding: Encodable, Equatable {
            let homepageUrl: String
        }

        let name: String
        let version: String
        let branding: Branding
    }

    struct File: Encodable, Equatable {
        let language: String
        let source: String
        let mutants: [Mutant]
    }

    struct Mutant: Encodable, Equatable {
        let id: String
        let mutatorName: String
        let replacement: String
        let description: String
        let location: Location
        let status: Status
        let statusReason: String
    }

    struct Location: Encodable, Equatable {
        let start: Position
        let end: Position
    }

    /// Lines and columns start at 1. A column counts UTF-16 code units, like the JavaScript tools that
    /// read the report. Muter counts UTF-8 bytes, so the columns are converted.
    struct Position: Encodable, Equatable {
        let line: Int
        let column: Int
    }

    enum Status: String, Encodable, Equatable {
        case killed = "Killed"
        case survived = "Survived"
        case noCoverage = "NoCoverage"
        case compileError = "CompileError"
        case runtimeError = "RuntimeError"
        case timeout = "Timeout"
        case ignored = "Ignored"
    }

    let schemaVersion: String
    let thresholds: Thresholds
    let projectRoot: String?
    let framework: Framework
    let files: [String: File]
}

extension StrykerReport {
    /// Stryker's default thresholds. Muter has no thresholds of its own.
    static let defaultThresholds = Thresholds(high: 80, low: 60)

    init(outcome: MutationTestOutcome, readFile: (String) -> String?) {
        let mutations = outcome.mutations.sorted(by: Self.sourceOrder)

        var mutantsByPath: [String: [Mutant]] = [:]
        var linesByPath: [String: [Substring]] = [:]
        var sourceByPath: [String: String] = [:]

        for (index, mutation) in mutations.enumerated() {
            let path = Self.reportPath(of: mutation)
            if sourceByPath[path] == nil {
                let source = readFile(mutation.originalProjectPath) ?? ""
                sourceByPath[path] = source
                linesByPath[path] = source.split(separator: "\n", omittingEmptySubsequences: false)
            }

            mutantsByPath[path, default: []].append(
                Mutant(
                    // Muter has no stable id for a mutant across runs. The ids number the mutants
                    // of this report in source order.
                    id: String(index + 1),
                    mutatorName: mutation.point.mutationOperatorId.rawValue,
                    replacement: Self.replacement(of: mutation),
                    description: mutation.snapshot.description,
                    location: Self.location(of: mutation, lines: linesByPath[path] ?? []),
                    status: Status(mutation.testSuiteOutcome),
                    statusReason: Self.statusReason(of: mutation)
                )
            )
        }

        let projectRoot = mutations.first.flatMap(Self.projectRoot(of:))
        var files: [String: File] = mutantsByPath.reduce(into: [:]) { files, entry in
            files[entry.key] = File(
                language: "swift",
                source: sourceByPath[entry.key] ?? "",
                mutants: entry.value
            )
        }

        // Muter does not mutate a file that the tests do not cover at all. The report still lists
        // it, with no mutants, like Muter's other reports.
        let mutatedRoot = mutations.first.flatMap(Self.mutatedProjectRoot(of:))
        for path in outcome.coverage.filesWithoutCoverage {
            let relativePath = Self.relativePath(of: path, roots: [mutatedRoot, projectRoot])
            guard files[relativePath] == nil else {
                continue
            }

            let originalPath = projectRoot.map { $0 + "/" + relativePath } ?? path
            files[relativePath] = File(
                language: "swift",
                source: readFile(originalPath) ?? readFile(path) ?? "",
                mutants: []
            )
        }

        self.init(
            schemaVersion: "2",
            thresholds: Self.defaultThresholds,
            projectRoot: projectRoot,
            framework: Framework(
                name: "Muter",
                version: version,
                branding: .init(homepageUrl: "https://github.com/muter-mutation-testing/muter")
            ),
            files: files
        )
    }

    /// The root of the mutated copy of the project, where the coverage paths point.
    private static func mutatedProjectRoot(of mutation: MutationTestOutcome.Mutation) -> String? {
        let suffix = "/" + mutation.relativePath
        guard !mutation.relativePath.isEmpty,
              mutation.point.filePath.hasSuffix(suffix)
        else {
            return nil
        }

        return String(mutation.point.filePath.dropLast(suffix.count))
    }

    /// `path` from the first root that contains it, or `path` itself.
    private static func relativePath(of path: String, roots: [String?]) -> String {
        for case let root? in roots where path.hasPrefix(root + "/") {
            return String(path.dropFirst(root.count + 1))
        }

        return path
    }

    private static func sourceOrder(
        _ lhs: MutationTestOutcome.Mutation,
        _ rhs: MutationTestOutcome.Mutation
    ) -> Bool {
        (reportPath(of: lhs), lhs.point.position.line, lhs.point.position.column, lhs.point.mutationOperatorId.rawValue)
            < (reportPath(of: rhs), rhs.point.position.line, rhs.point.position.column, rhs.point.mutationOperatorId.rawValue)
    }

    /// The file's path from the project root, as the schema asks. The full path is the fallback.
    private static func reportPath(of mutation: MutationTestOutcome.Mutation) -> String {
        mutation.relativePath.isEmpty ? mutation.originalProjectPath : mutation.relativePath
    }

    private static func projectRoot(of mutation: MutationTestOutcome.Mutation) -> String? {
        let suffix = "/" + mutation.relativePath
        guard !mutation.relativePath.isEmpty,
              mutation.originalProjectPath.hasSuffix(suffix)
        else {
            return nil
        }

        return String(mutation.originalProjectPath.dropLast(suffix.count))
    }

    /// The code that replaces the mutated code. A mutant from an older test plan has only its
    /// snapshot, where a removed statement is replaced by nothing.
    private static func replacement(of mutation: MutationTestOutcome.Mutation) -> String {
        if let replacement = mutation.replacement {
            return replacement
        }

        return mutation.point.mutationOperatorId == .removeSideEffects ? "" : mutation.snapshot.after
    }

    private static func statusReason(of mutation: MutationTestOutcome.Mutation) -> String {
        let reason = mutation.testSuiteOutcome.asMutationTestOutcome
        guard let failedTests = mutation.failedTests, failedTests > 0 else {
            return reason
        }

        return "\(reason), \(failedTests) \(failedTests == 1 ? "test" : "tests") failed"
    }

    private static func location(
        of mutation: MutationTestOutcome.Mutation,
        lines: [Substring]
    ) -> Location {
        let start: MutationPosition
        let end: MutationPosition
        if let range = mutation.range {
            start = range.start
            end = range.end
        } else {
            // A mutant from an older test plan has only its position. The location then covers the
            // original code on that line.
            start = mutation.point.position
            end = MutationPosition(
                line: start.line,
                column: start.column + mutation.snapshot.before.utf8.count
            )
        }

        let startPosition = position(line: start.line, utf8Column: start.column, lines: lines)
        let endPosition = position(line: end.line, utf8Column: end.column, lines: lines)

        return Location(
            start: startPosition,
            end: (endPosition.line, endPosition.column) < (startPosition.line, startPosition.column)
                ? startPosition
                : endPosition
        )
    }

    private static func position(line: Int, utf8Column: Int, lines: [Substring]) -> Position {
        let line = max(line, 1)
        let utf8Column = max(utf8Column, 1)
        guard line <= lines.count else {
            return Position(line: line, column: utf8Column)
        }

        let prefix = lines[line - 1].utf8.prefix(utf8Column - 1)
        return Position(
            line: line,
            column: String(decoding: prefix, as: UTF8.self).utf16.count + 1
        )
    }
}

extension StrykerReport.Status {
    /// Muter's outcome as a Stryker status. Muter counts a run that crashed as a killed mutant, and
    /// Stryker counts `RuntimeError` as not valid, so a crash is `Killed`. The status reason tells it
    /// apart. With this mapping, the score that the tools show is Muter's mutation score.
    init(_ outcome: TestSuiteOutcome) {
        switch outcome {
        case .passed:
            self = .survived
        case .failed, .runtimeError:
            self = .killed
        case .timeout:
            self = .timeout
        case .buildError:
            self = .compileError
        case .noCoverage:
            self = .noCoverage
        case .ignored:
            self = .ignored
        }
    }
}
