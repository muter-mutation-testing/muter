import XCTest

extension XCTestCase {
    var testDirectory: String {
        return URL(string: #file)!.deletingLastPathComponent().absoluteString
    }
    
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
}
