@testable import muterCore
import Quick
import Nimble

class SourceFileDiscoverySpec: QuickSpec {
    override func spec() {
        describe("Swift Source File Discovery") {
            it("discovers Swift files recursively and returns the results alphabetically") {
                let path = "\(self.fixturesDirectory)/FilesToDiscover"
                let discoveredPaths = discoverSourceFiles(inDirectoryAt: path)

                expect(discoveredPaths).to(equal([
                    "\(path)/Directory1/file3.swift",
                    "\(path)/Directory2/Directory3/file6.swift",
                    "\(path)/ExampleApp/ExampleAppCode.swift",
                    "\(path)/file1.swift",
                    "\(path)/file2.swift",
                ]))
            }

            it("discovers Swift files applying a user-provided exclude list") {
                let path = "\(self.fixturesDirectory)/FilesToDiscover"
                let discoveredPaths = discoverSourceFiles(inDirectoryAt: path,
                                                          excludingPathsIn: ["ExampleApp"])
                expect(discoveredPaths).to(equal([
                    "\(path)/Directory1/file3.swift",
                    "\(path)/Directory2/Directory3/file6.swift",
                    "\(path)/file1.swift",
                    "\(path)/file2.swift",
                ]))
            }

            it("discovers 0 Swift files in a directory that doesn't exist") {
                expect(discoverSourceFiles(inDirectoryAt: "I don't exist")).to(beEmpty())
            }

            it("ignores files that aren't Swift files") {
                let path = "\(self.fixturesDirectory)/FilesToDiscover"

                expect(discoverSourceFiles(inDirectoryAt: "\(path)/Directory4")).to(beEmpty())
                expect(discoverSourceFiles(inDirectoryAt: "\(path)/Directory2")).to(equal([
                    "\(path)/Directory2/Directory3/file6.swift",
                ]))
            }
        }

    }
}

