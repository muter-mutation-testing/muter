import XCTest
class MutationTesterDelegateTests: XCTestCase {
    var delegate: MutationTester.Delegate!
    
    override func setUp() {
        delegate = MutationTester.Delegate(configuration: MuterConfiguration.fromFixture(at: configurationPath)!,
                                           swapFilePathsByOriginalPath: [:])
    }
    
    func test_loadingANonexistentFileReturnsNil() {
        XCTAssertNil(delegate.sourceFromFile(at: "path/that/does/not/exist"))
    }
}
