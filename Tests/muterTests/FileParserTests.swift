import XCTest
import class Foundation.Bundle

final class FileParserTests: XCTestCase {
    
    func test_loadsASwiftFileIntoMemoryForMutationTesting() {
        do {
            _ = try FileParser.load(path: "/Users/seandorian/Code/Swift/muter/Tests/muterTests/fixtures/sample.swift")
        } catch {
            XCTFail("expected success but got error: \(error)")
        }
    }
    
    static var allTests = [
        ("\(test_loadsASwiftFileIntoMemoryForMutationTesting)", test_loadsASwiftFileIntoMemoryForMutationTesting),
    ]
}
