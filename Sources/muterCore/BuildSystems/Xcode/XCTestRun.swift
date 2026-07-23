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

        if let testConfigurations = copy[testConfigurationsKey] as? [AnyHashable] {
            // TestPlan configuration
            let newTestConfigurations = testConfigurations.map { testConfiguration in
                if var newTestConfiguration = testConfiguration as? [String: AnyHashable],
                   let testTargets = newTestConfiguration[testTargetsKey] as? [AnyHashable] {
                    let newTestTargets = testTargets.map { testTarget in
                        if let newTestTarget = testTarget as? [String: AnyHashable] {
                            return updateEnvironmentVariables(
                                forConfiguration: newTestTarget,
                                key: key
                            ) as AnyHashable
                        }
                        return testTarget
                    }

                    newTestConfiguration[testTargetsKey] = newTestTargets

                    return newTestConfiguration as AnyHashable
                }
                return testConfiguration
            }

            copy[testConfigurationsKey] = newTestConfigurations
        } else {
            // Legacy Tests configuration
            for (plistEntry, plistValue) in copy {
                if let testConfiguration = plistValue as? [String: AnyHashable] {
                    copy[plistEntry] = updateEnvironmentVariables(
                        forConfiguration: testConfiguration,
                        key: key
                    )
                }
            }
        }

        return copy
    }

    private func updateEnvironmentVariables(
        forConfiguration configuration: [String: AnyHashable],
        key: String
    ) -> [String: AnyHashable] {
        let environmentVariablesKey = "EnvironmentVariables"
        var configuration = configuration

        // Create the `EnvironmentVariables` dict when absent instead of skipping. A freshly generated
        // .xctestrun has no such dict for a target, so the old `keys.contains` guard silently never
        // wrote the schemata activation var. On the `test-without-building -xctestrun` path (used for
        // simulator-hosted targets, where the env must ride in via the xctestrun rather than the parent
        // process) the mutant then never activated in the test host — every mutant became a false
        // "survived", i.e. a phantom 0% score.
        var allEnvironmentVariables = configuration[environmentVariablesKey] as? [String: AnyHashable] ?? [:]
        allEnvironmentVariables[key] = isMuterRunningValue
        allEnvironmentVariables[isMuterRunningKey] = isMuterRunningValue

        configuration[environmentVariablesKey] = allEnvironmentVariables

        return configuration
    }
}
