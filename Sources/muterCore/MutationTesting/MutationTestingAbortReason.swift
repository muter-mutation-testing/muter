public enum MutationTestingAbortReason: Equatable {
    case baselineTestFailed
    case tooManyBuildErrors
    case unknownError(String)
}

extension MutationTestingAbortReason: CustomStringConvertible {
    public var description: String {
        switch self {
        case .baselineTestFailed:
            return """
            Muter noticed that your test suite initially failed to compile or produced a test failure.
            
            This is usually due to misconfiguring the "executable" and "arguments" options inside of your muter.conf.json.
            Alternatively, it could mean you have a nondeterministic test failure in your test suite.
            
            We recommend you try your settings out in a terminal prior to using Muter for the best configuration experience.
            We also recommend removing tests which you know to be flaky from the set of tests that Muter exercises.
            
            If you believe that you found a bug and can reproduce it, or simply need help getting started, please consider opening an issue
            at https://github.com/SeanROlszewski/muter
            """
            
        case .tooManyBuildErrors:
            return """
            Muter noticed the last 5 attempts to apply a mutation operator resulted in a build error within your code base.
            This is considered unlikely and abnormal. If you can reproduce this, please consider filing an issue at
            https://github.com/SeanROlszewski/muter/issues/
            """
            
        case .unknownError(let error):
            return "Muter encountered an error running your test suite and can't continue\n\(error)"
        }
    }
}
