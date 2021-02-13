import Quick
import Nimble
import Foundation

class FileManagerCanarySpec: QuickSpec {
    override func spec() {
        describe("FileManager") {
            it("names temporary files predictably") {
                let volumeRoot = URL(fileURLWithPath: "/")
                do {
                    let temporaryDirectory = try FileManager.default.url(
                        for: .itemReplacementDirectory,
                        in: .userDomainMask,
                        appropriateFor: volumeRoot,
                        create: true
                    )
                    expect(temporaryDirectory.absoluteString).to(contain("/var/folders"))
                    expect(temporaryDirectory.absoluteString).to(contain("/T/TemporaryItems/"))
                } catch {
                    fail("Expected no errors, but got \(error)")
                }
            }
        }
    }
}
