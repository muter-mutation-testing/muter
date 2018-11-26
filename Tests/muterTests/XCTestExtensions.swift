import XCTest

extension XCTestCase {
    var productsDirectory: URL {
        #if os(macOS)
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        fatalError("couldn't find the products directory")
        #else
        return Bundle.main.bundleURL
        #endif
    }
    
    var testDirectory: String {
        return String(
            URL(string: #file)!
                .deletingLastPathComponent()
                .absoluteString
                .dropLast()
        )
    }
    
    var fixturesDirectory: String { return "\(testDirectory)/fixtures" }
    var configurationPath: String { return "\(fixturesDirectory)/muter.conf.json" }
}
