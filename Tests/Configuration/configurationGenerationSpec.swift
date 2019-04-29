import Quick
import Nimble
@testable import muterCore

class ConfigurationGenerationSpec: QuickSpec {
    override func spec() {
        
        let iosXcodeProjectConfiguration = MuterConfiguration(executable: "/usr/bin/xcodebuild",
                                                              arguments: ["-project",
                                                                          "iOSApp.xcodeproj",
                                                                          "-scheme",
                                                                          "iOSApp",
                                                                          "-destination",
                                                                          "platform=iOS Simulator,name=iPhone 8",
                                                                          "test"])
        
        describe("generating a configuration") {
            context("for a project using Swift Package Manager") {
                context("when there isn't an Xcode project in the project directory") {
                    it("prefills a configuration to use the `swift test` command") {
                        let projectDirectoryContents = ["/some/path/Package.swift",
                                                        "/some/path/main.swift",]
                        
                        let generatedConfiguration = MuterConfiguration(from: projectDirectoryContents)
                        expect(generatedConfiguration) == MuterConfiguration(executable: "/usr/bin/swift",
                                                                             arguments: ["test"])
                    }
                }
                context("when there is an Xcode project file in the project directory") {
                    it("prefills a configuration to use `xcodebuild -project test` with iOS-specific settings") {
                        let projectDirectoryContents = ["/some/path/Package.swift",
                                                        "/some/path/main.swift",
                                                        "\(self.fixturesDirectory)/XcodeProjectFiles/iOSApp.xcodeproj",]
                        
                        let generatedConfiguration = MuterConfiguration(from: projectDirectoryContents)
                        expect(generatedConfiguration) == iosXcodeProjectConfiguration
                    }
                }
                
            }
            
            context("for an iOS project using a Xcode project") {
                it("prefills a configuration to use `xcodebuild -project -destination test`") {
                    let projectDirectoryContents = ["\(self.fixturesDirectory)/XcodeProjectFiles/iOSApp.xcodeproj",
                                                    "/some/path/AppDelegate.swift",]
                    
                    let generatedConfiguration = MuterConfiguration(from: projectDirectoryContents)
                    expect(generatedConfiguration) == iosXcodeProjectConfiguration
                }
            }
            
            context("for a macOS project using a Xcode project") {
                it("prefills a configuration to use `xcodebuild -project test`") {
                    let projectDirectoryContents = ["\(self.fixturesDirectory)/XcodeProjectFiles/CocoaApp.xcodeproj",
                                                    "/some/path/AppDelegate.swift",]
                    
                    let generatedConfiguration = MuterConfiguration(from: projectDirectoryContents)
                    expect(generatedConfiguration) == MuterConfiguration(executable: "/usr/bin/xcodebuild",
                                                                         arguments: ["-project",
                                                                                     "CocoaApp.xcodeproj",
                                                                                     "-scheme",
                                                                                     "CocoaApp",
                                                                                     "test"])
                }
            }
            
            context("for project using a Xcode workspace") {
                it("prevails a configuration to use `xcodebuild -workspace test`") {
                    let projectDirectoryContents = ["/some/path/ExampleApp.xcworkspace",
                                                    "/some/path/AppDelegate.swift"]
                    
                    let generatedConfiguration = MuterConfiguration(from: projectDirectoryContents)
                    expect(generatedConfiguration) == MuterConfiguration(executable: "/usr/bin/xcodebuild",
                                                                         arguments: ["-workspace",
                                                                                     "ExampleApp.xcworkspace",
                                                                                     "-scheme",
                                                                                     "ExampleApp",
                                                                                     "-destination",
                                                                                     "platform=iOS Simulator,name=iPhone 8",
                                                                                     "test"])
                }
            }
            
            context("for a project it can't figure out") {
                it("defaults to empty configuration") {
                    let generatedConfiguration = MuterConfiguration(from: ["/some/path/main.swift"])
                    expect(generatedConfiguration) == MuterConfiguration(executable: "", arguments: [])
                }
            }
        }
    }
}

