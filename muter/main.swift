import muterCore
import ArgumentParser

struct MuterCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "muter",
        abstract: "🔎 Automated mutation testing for Swift 🕳️",
        version: version,
        subcommands: [
            Init.self,
            Run.self,
        ],
        defaultSubcommand: Run.self
    )
}

MuterCommand.main()
