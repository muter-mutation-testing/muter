public enum MutationTestingAbortReason: Equatable {
    case baselineTestFailed(log: String)
    case tooManyBuildErrors
    case unknownError(description: String)
}

extension MutationTestingAbortReason: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .baselineTestFailed(log):
            return """
            Muter noticed that your test suite initially failed to compile or produced a test failure.

            Assuming you have no build errors, this is usually due to misconfiguring the "executable" and "arguments" options inside of your \(
                MuterConfiguration
                    .fileName
            ).
            Alternatively, it could mean you have a nondeterministic test failure in your test suite.

            We recommend you try your settings out in a terminal prior to using Muter for the best configuration experience.
            We also recommend removing tests which you know are flaky from the set of tests that Muter exercises.

            Here's the log XCTest produced:

            \(log)
            """

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
