import Foundation

public enum MutationTestingAbortReason: Equatable {
    /// `mutatedFilePaths` are the files Muter rewrote to insert mutants. A compile error in one of
    /// them points at Muter's own rewriting rather than at the user's configuration, so the message
    /// needs them to tell the two apart.
    case baselineTestFailed(log: String, mutatedFilePaths: [String])
    case tooManyBuildErrors
    case unknownError(description: String)
}

extension MutationTestingAbortReason: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .baselineTestFailed(log, mutatedFilePaths):
            return Self.baselineTestFailedDescription(
                log: log,
                mutatedFilePaths: mutatedFilePaths
            )

        case .tooManyBuildErrors:
            return """
            Muter noticed the last 5 attempts to apply a mutation operator resulted in a build error within your code base.
            This is considered unlikely and abnormal. If you can reproduce this, please consider filing an issue at
            https://github.com/muter-mutation-testing/muter/issues/
            """

        case let .unknownError(error):
            return "Muter encountered an error running your test suite and can't continue\n\(error)"
        }
    }
}

private extension MutationTestingAbortReason {
    static func baselineTestFailedDescription(
        log: String,
        mutatedFilePaths: [String]
    ) -> String {
        """
        \(baselineTestFailedCause(log: log, mutatedFilePaths: mutatedFilePaths))

        \(baselineTestFailedEvidence(log: log))
        """
    }

    static func baselineTestFailedCause(
        log: String,
        mutatedFilePaths: [String]
    ) -> String {
        if let error = CompilerError.first(in: log, inFilesAt: mutatedFilePaths) {
            return """
            Muter could not establish a baseline because a file it had mutated failed to compile:

              \(error.description)

            Muter rewrites the files it mutates before running your test suite, so a compile error in \
            \(error.fileName) is most likely a bug in Muter's own rewriting rather than a problem with \
            your \(MuterConfiguration.fileNameWithExtension).

            Please report this at https://github.com/muter-mutation-testing/muter/issues/ and include \
            the log below. To rule out a pre-existing error, check that \(error.fileName) compiles in \
            your unmutated project.
            """
        }

        return """
        Muter noticed that your test suite initially failed to compile or produced a test failure.

        Assuming you have no build errors, this is usually due to misconfiguring the "executable" and \
        "arguments" options inside of your \(MuterConfiguration.fileName).
        Alternatively, it could mean you have a nondeterministic test failure in your test suite.

        We recommend you try your settings out in a terminal prior to using Muter for the best configuration experience.
        We also recommend removing tests which you know are flaky from the set of tests that Muter exercises.
        """
    }

    static func baselineTestFailedEvidence(log: String) -> String {
        guard !log.trimmed.isEmpty else {
            return """
            Muter captured no output at all from your test command, so it has no log to show. That \
            normally means the command never started — check that "executable" in \
            \(MuterConfiguration.fileNameWithExtension) names a command Muter can launch.
            """
        }

        return """
        Here's the log your test command produced:

        \(log)
        """
    }
}

/// A `file:line:column: error: message` diagnostic parsed out of a compiler or test log.
struct CompilerError: Equatable {
    let filePath: String
    let line: Int
    let column: Int
    let message: String

    var fileName: String {
        filePath.lastPathComponent
    }

    var description: String {
        "\(fileName):\(line):\(column): error: \(message)"
    }
}

extension CompilerError {
    /// The first compile error in `log` reported against any of `filePaths`.
    ///
    /// Matching is by file name rather than full path: the log's paths point into Muter's copy of the
    /// project, while the paths Muter records for its mutants are relative to the original.
    static func first(
        in log: String,
        inFilesAt filePaths: [String]
    ) -> CompilerError? {
        let fileNames = Set(filePaths.map(\.lastPathComponent))

        return all(in: log).first { fileNames.contains($0.fileName) }
    }

    static func all(in log: String) -> [CompilerError] {
        log.split(separator: "\n").compactMap { from(logLine: String($0)) }
    }

    /// Parses one `/path/to/File.swift:12:34: error: expected expression` line. The message runs to the
    /// end of the line; anything that doesn't have exactly this shape is not a diagnostic.
    private static func from(logLine: String) -> CompilerError? {
        let components = logLine.split(separator: ":", maxSplits: 4, omittingEmptySubsequences: false)
        guard components.count == 5,
              let line = Int(components[1]),
              let column = Int(components[2]),
              String(components[3]).trimmed == "error",
              !String(components[4]).trimmed.isEmpty
        else {
            return nil
        }

        return CompilerError(
            filePath: String(components[0]),
            line: line,
            column: column,
            message: String(components[4]).trimmed
        )
    }
}

private extension String {
    var lastPathComponent: String {
        URL(fileURLWithPath: self).lastPathComponent
    }
}
