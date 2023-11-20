@testable import muterCore
import TestingExtensions
import XCTest

final class ProcessFactoryTests: XCTestCase {
    func test_processConfiguration() {
        let process = ProcessWrapper.Factory.makeProcess()

        XCTAssertEqual(process.qualityOfService, .userInitiated)
        XCTAssertEqual(process.environment, ProcessInfo.processInfo.environment)
    }
}
