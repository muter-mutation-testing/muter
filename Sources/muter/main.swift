import Darwin
import muterCore
import ArgumentParser

if #available(OSX 10.13, *) {
    struct MuterCommand: ParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "muter",
            abstract: "🔎 Automated mutation testing for Swift 🕳️",
            version: "v13",
            subcommands: [
                Init.self,
                Run.self,
            ],
            defaultSubcommand: Run.self
        )
    }

    MuterCommand.main()
} else {
    print("Muter requires macOS 10.13 or higher")
    exit(1)
}
