import XCTest
@testable import muterCore

class MuterCodeCoveragePrincipalClass: NSObject {
    class CompletionObserver: NSObject, XCTestObservation {
        func testBundleDidFinish(_ testBundle: Bundle) {
            CodeCoverageInstrumenter.shared.persistFunctionCalls()
        }
    }

    override init() { XCTestObservationCenter.shared.addTestObserver(CompletionObserver())
    }
}
