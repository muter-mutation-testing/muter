import muterCore
import XCTest

final class cliSubcommandTests: XCTestCase {

    override func tearDown() {
        let workingDirectory = self.testDirectory
        try? FileManager.default.removeItem(atPath: "\(workingDirectory)/muter.conf.json")
    }

    func test_initSubcommandCreatesConfigurationFile() {
        let workingDirectory = self.testDirectory

        try! setupMuter(using: FileManager.default, and: workingDirectory)
        
        guard let contents = FileManager.default.contents(atPath: "\(workingDirectory)/muter.conf.json"),
            let _ = try? JSONDecoder().decode(MuterConfiguration.self, from: contents) else {
              
                XCTFail("Expected a valid configuration file to be written")
                return
        }
    }
}
