import XCTest

@testable import muterCore

final class InitCommandTests: XCTestCase {
    private lazy var sut = Init(directory: rootTestDirectory)
    
    func test_createsAConfigurationFileNamedMuterConfYmlWithPlaceholderValuesInASpecifiedDirectory() throws {
        try sut.run()
        guard let contents = FileManager.default.contents(atPath: "\(rootTestDirectory)/muter.conf.yml"),
              let _ = try? MuterConfiguration(from: contents) else {
            XCTFail("Expected a valid configuration file to be written")
            return
        }
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        
        try FileManager.default.removeItem(atPath: "\(rootTestDirectory)/\(MuterConfiguration.fileNameWithExtension)")
    }
}
