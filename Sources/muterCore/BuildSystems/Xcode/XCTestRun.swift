import Foundation

struct XCTestRun: Equatable {
    private let plist: [String: AnyHashable]

    init(_ plist: [AnyHashable: Any] = [:]) {
        self.plist = plist.keys
            .compactMap { $0 as? String }
            .reduce(into: [:]) { partialResult, key in
                partialResult[key] = plist[key] as? AnyHashable
            }
    }

    func updateEnvironmentVariable(
        setting key: String
    ) -> [String: AnyHashable] {
        var copy = plist
        let environmentVariablesKey = "EnvironmentVariables"

        for (plistEntry, plistValue) in copy {
            if var testConfiguration = plistValue as? [String: AnyHashable],
               testConfiguration.keys.contains(environmentVariablesKey),
               var allEnvironmentVariables = testConfiguration[environmentVariablesKey] as? [String: AnyHashable] {
                allEnvironmentVariables[key] = "YES"

                testConfiguration[environmentVariablesKey] = allEnvironmentVariables

                copy[plistEntry] = testConfiguration
            }
        }

        return copy
    }
}
