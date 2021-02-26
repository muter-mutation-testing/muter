import Foundation

enum BuildSystem: Error {
    case buildError
}

protocol BuildSystemRunner: AnyObject {
    func run(
        process makeProcess: @escaping () -> Launchable,
        with configuration: MuterConfiguration
    ) -> Result<Coverage, BuildSystem>
}

extension BuildSystemRunner {
    func toString(_ data: Data) -> String? {
        String(data: data, encoding: .utf8)
    }

    func notEmpty(_ input: String) -> String? {
        !input.isEmpty ? input : nil
    }
}

func runProcess<A>(
    _ makeProcess: () -> Launchable,
    url: String,
    arguments: [String],
    _ transform: (Data) -> A?
) -> A? {
    let process = makeProcess()
    process.standardOutput = Pipe()
    process.executableURL = URL(fileURLWithPath: url)
    process.arguments = arguments

    try? process.run()

    let output = process.availableData ?? Data()

    process.waitUntilExit()

    return transform(output)
}

func runner(for executable: String) -> BuildSystemRunner? {
    guard let buildSystem = executable.components(separatedBy: "/").last?.trimmed else {
        return nil
    }
    
    switch buildSystem {
    case "swift": return SwiftRunner()
    case "xcodebuild": return XcodeRunner()
    default: return nil
    }
}
