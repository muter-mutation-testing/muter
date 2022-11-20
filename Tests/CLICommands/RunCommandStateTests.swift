import XCTest

@testable import muterCore

final class RunCommandStateTests: XCTestCase {
    private let sut = RunCommandState(
        from: .make(
            filesToMutate: [
                "/path/to/file1.swift,/path/to/file3.swift,/path/to/file3.swift,",
            ]
        )
    )
    
    func test_shouldParseFilesToMutate() {
        XCTAssertEqual(sut.filesToMutate.count, 3)
        XCTAssertEqual(sut.filesToMutate[safe: 0], "/path/to/file1.swift")
        XCTAssertEqual(sut.filesToMutate[safe: 1], "/path/to/file3.swift")
        XCTAssertEqual(sut.filesToMutate[safe: 2], "/path/to/file3.swift")
    }
}
