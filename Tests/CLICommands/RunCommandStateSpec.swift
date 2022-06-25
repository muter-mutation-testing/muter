import Quick
import Nimble
@testable import muterCore

final class RunCommandStateSpec: QuickSpec {
    override func spec() {
        describe("RunCommandState") {
            var state: RunCommandState!

            describe("--filesToMutate") {
                context("when files are separated by comma") {
                    beforeEach {
                        state = RunCommandState(
                            from: .make(
                                filesToMutate: [
                                    "/path/to/file1.swift,/path/to/file3.swift,/path/to/file3.swift,",
                                ]
                            )
                        )
                    }

                    it("should parse") {
                        expect(state.filesToMutate).to(haveCount(3))
                        expect(state.filesToMutate[0]).to(equal("/path/to/file1.swift"))
                        expect(state.filesToMutate[1]).to(equal("/path/to/file3.swift"))
                        expect(state.filesToMutate[2]).to(equal("/path/to/file3.swift"))
                    }
                }
            }
        }
    }
}
