import Foundation

struct XCTestRun: Equatable {
    private let plist: [String: AnyHashable]

    init(_ plist: [String: AnyHashable] = [:]) {
        self.plist = plist
    }

    func updateEnvironmentVariable(
        setting key: String
    ) -> [String: AnyHashable] {
        var copy = plist
        let testConfigurationsKey = "TestConfigurations"
        let testTargetsKey = "TestTargets"
        let environmentVariablesKey = "EnvironmentVariables"

        if let testConfigurations = copy[testConfigurationsKey] as? [AnyHashable] {
            // Using Xcode's TestPlans
            let newTestConfigurations = testConfigurations.map { testConfiguration in
                if var newTestConfiguration = testConfiguration as? [String: AnyHashable],
                   let testTargets = newTestConfiguration[testTargetsKey] as? [AnyHashable] {
                    let newTestTargets = testTargets.map { testTarget in
                        if var newTestTarget = testTarget as? [String: AnyHashable],
                           var allEnvironmentVariables = newTestTarget[environmentVariablesKey] as? [String: AnyHashable] {
                            allEnvironmentVariables[key] = isMuterRunningValue
                            allEnvironmentVariables[isMuterRunningKey] = isMuterRunningValue

                            newTestTarget[environmentVariablesKey] = allEnvironmentVariables

                            return newTestTarget as AnyHashable
                        }
                        return testTarget
                    }

                    newTestConfiguration[testTargetsKey] = newTestTargets

                    return newTestConfiguration as AnyHashable
                }
                return testConfiguration
            }

            copy[testConfigurationsKey] = newTestConfigurations
        } else { // Legacy Tests config
            for (plistEntry, plistValue) in copy {
                if var testConfiguration = plistValue as? [String: AnyHashable],
                   testConfiguration.keys.contains(environmentVariablesKey),
                   var allEnvironmentVariables = testConfiguration[environmentVariablesKey] as? [String: AnyHashable] {
                    allEnvironmentVariables[key] = isMuterRunningValue
                    allEnvironmentVariables[isMuterRunningKey] = isMuterRunningValue

                    testConfiguration[environmentVariablesKey] = allEnvironmentVariables

                    copy[plistEntry] = testConfiguration
                }
            }
        }

        return copy
    }
}
