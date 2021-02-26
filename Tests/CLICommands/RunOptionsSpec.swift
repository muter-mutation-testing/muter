import Quick
import Nimble
@testable import muterCore

final class RunOptionsSepc: QuickSpec {
    override func spec() {
        describe("reporter choice") {
            var runOptions: RunOptions!

            context("when they want a json") {
                it("then return it") {
                    runOptions = .make(
                        shouldOutputJson: true,
                        shouldOutputXcode: false,
                        shouldOutputHtml: false
                    )

                    expect(runOptions.reporter).to(beAKindOf(JsonReporter.self))
                }
            }
            
            context("when they want xcode") {
                it("then return it") {
                    runOptions = .make(
                        shouldOutputJson: false,
                        shouldOutputXcode: true,
                        shouldOutputHtml: false
                    )

                    expect(runOptions.reporter).to(beAKindOf(XcodeReporter.self))
                }
            }
            
            context("when they want plain text") {
                it("then return it") {
                    runOptions = .make(
                        shouldOutputJson: false,
                        shouldOutputXcode: false,
                        shouldOutputHtml: false
                    )

                    expect(runOptions.reporter).to(beAKindOf(PlainTextReporter.self))
                }
            }

            context("when they want an html") {
                it("then return it") {
                    runOptions = .make(
                        shouldOutputJson: false,
                        shouldOutputXcode: false,
                        shouldOutputHtml: true
                    )

                    expect(runOptions.reporter).to(beAKindOf(HTMLReporter.self))
                }
            }
        }
    }
}
