
import Foundation

final class PrelaunchiOSSimulator: MutationStep {
    private static let maximumPrelaunchSimulator = 3

    @Dependency(\.process)
    private var process: ProcessFactory

    func run(
        with state: AnyMutationTestState
    ) async throws -> [MutationTestState.Change] {

        let xcrunPath = process().which("xcrun") ?? ""
        guard let simulatorsListOutput: Data = process().runProcess(
            url: xcrunPath,
            arguments: ["simctl", "list", "--json"]
        ) else { return [] }

        do {

            // Get selected simulator from the configuration file
            guard let destinationIndex = state.muterConfiguration.testCommandArguments.firstIndex(of: "-destination") else { return [] }
            let configDestination = state.muterConfiguration.testCommandArguments[destinationIndex + 1]

            // Retrieve list of simulators
            let simulatorsJson = try (JSONSerialization.jsonObject(with: simulatorsListOutput) as? [String: AnyHashable]) ??
                [:]

            let allDevices = (simulatorsJson["devices"] as? [String: AnyHashable]) ?? [:]
            let newestRuntime = allDevices.keys.filter { $0.contains("iOS") }.sorted().last ?? ""
            let devicesForRunTime = (allDevices[newestRuntime] as? [AnyHashable]) ?? []
            let iOSSimulatorDevices = try devicesForRunTime
                .compactMap { try JSONSerialization.data(withJSONObject: $0) }
                .compactMap { try JSONDecoder().decode(Simulator.self, from: $0) }
                .filter(\.isAvailable)
                .sorted(by: { $0.deviceTypeIdentifier > $1.deviceTypeIdentifier })
                .filter { $0.name.contains("iPhone") }

            let selectedSimulatorUDID = iOSSimulatorDevices.first {
                configDestination.contains($0.name) || configDestination.contains($0.udid)
            }?.udid

            // Pre-launch simulators, including the specific config simulator
            var preLaunchSimulatorUDIDs: [String] = []
            if let selectedSimulatorUDID {
                preLaunchSimulatorUDIDs.append(selectedSimulatorUDID)
            }

            let addtionalUDIDs = iOSSimulatorDevices
                .map(\.udid)
                .filter { $0 != selectedSimulatorUDID }
                .prefix(PrelaunchiOSSimulator.maximumPrelaunchSimulator - preLaunchSimulatorUDIDs.count)

            preLaunchSimulatorUDIDs += addtionalUDIDs

            for udid in preLaunchSimulatorUDIDs {
                _ = process().runProcess(
                    url: xcrunPath,
                    arguments: [
                        "simctl",
                        "boot",
                        udid
                    ]
                )
            }

            return [.prelaunchSimulator(preLaunchSimulatorUDIDs)]

        } catch {
            return []
        }
    }

}
