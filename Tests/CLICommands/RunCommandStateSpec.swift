import Quick
import Nimble
import Foundation
@testable import muterCore

class RunCommandStateSpec: QuickSpec {
    override func spec() {
        describe("RunCommandStateSpec") {
            var sut: RunCommandState!
            
            beforeEach {
                sut = RunCommandState()
            }
            
            describe("filesWithoutCoverage") {
                beforeEach {
                    sut.muterConfiguration = .init(
                        excludeList: ["/path/to/ignore.swift"]
                    )
                }
                
                it("should append it with excluded files") {
                    sut.apply([
                        .filesWithoutCoverage(["something/to/ignore.swift"])
                    ])
                    
                    expect(sut.muterConfiguration.excludeFileList).to(equal([
                        "/path/to/ignore.swift", "something/to/ignore.swift"
                    ]))
                }
            }
        }
    }
}
