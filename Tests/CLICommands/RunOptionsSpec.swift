import Quick
import Nimble
@testable import muterCore

final class RunOptionsSepc: QuickSpec {
    override func spec() {
        describe("reporter choice") {
            var runOptions: RunOptions!

            context("when they want a json") {
                it("then return it") {
                    runOptions = .make(reportType: .json)

                    expect(runOptions.reportOptions.reporter).to(beAKindOf(JsonReporter.self))
                }
            }
            
            context("when they want xcode") {
                it("then return it") {
                    runOptions = .make(reportType: .xcode)

                    expect(runOptions.reportOptions.reporter).to(beAKindOf(XcodeReporter.self))
                }
            }
            
            context("when they want plain text") {
                it("then return it") {
                    runOptions = .make(reportType: .plain)

                    expect(runOptions.reportOptions.reporter).to(beAKindOf(PlainTextReporter.self))
                }
            }

            context("when they want an html") {
                it("then return it") {
                    runOptions = .make(reportType: .html)

                    expect(runOptions.reportOptions.reporter).to(beAKindOf(HTMLReporter.self))
                }
            }
        }
    }
}
