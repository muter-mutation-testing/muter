import ArgumentParser

struct MuterCommand: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "muter",
        abstract: "🔎 Automated mutation testing for Swift 🕳️",
        version: version,
        subcommands: [
            Init.self,
            Run.self,
            RunWithoutMutating.self,
            MutateWithoutRunning.self,
            Operator.self,
        ],
        defaultSubcommand: Run.self
    )
}

public enum Muter {
    public static func start() async {
        await MuterCommand.main()
    }
}
