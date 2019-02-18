@testable import muterCore

public extension MuterTestReport {
    public static var dummy: MuterTestReport {
        return .init(from:
            [
                .init(testSuiteOutcome: .failed,
                      appliedMutation: .negateConditionals,
                      filePath: "some path",
                      position: .firstPosition)
            ]
        )
    }
}
