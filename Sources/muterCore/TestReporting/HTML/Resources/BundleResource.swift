import class Foundation.Bundle

private class BundleFinder {}

extension Foundation.Bundle {
    /// Returns the resource bundle associated with the current Swift module.
    static var muter: Bundle = {
        let bundleName = "muter_muterCore"

        let candidates = [
            // Bundle should be present here when the package is linked into an App.
            Bundle.main.resourceURL,

            // Bundle should be present here when the package is linked into a framework.
            Bundle(for: BundleFinder.self).resourceURL,

            // For command-line tools.
            Bundle.main.bundleURL,
        ]

        for candidate in candidates {
            let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
            if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                return bundle
            }
        }
        fatalError("unable to find bundle named muter_muterCore")
    }()
}

extension Foundation.Bundle {
    static func resource(named: String, ofType type: String) -> String {
        Bundle.muter.path(forResource: named, ofType: type)
            .flatMap {
                try? String(contentsOfFile: $0)
            } ?? ""
    }
}
