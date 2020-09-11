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
            defaultSubcommand: Run.self)
    }

    MuterCommand.main()

    #warning("where to put this stuff from Commandant?")
//    let registry = CommandRegistry<MuterError>()
//    registry
//        .register(InitCommand())
//        .register(RunCommand())
//        .register(HelpCommand(registry: registry))
//        .main(defaultVerb: RunCommand().verb) { (error) in
//            print("""
//
//            ⚠️ ⚠️ ⚠️ ⚠️ ⚠️  Muter has encountered an error  ⚠️ ⚠️ ⚠️ ⚠️ ⚠️
//            \(error)
//
//
//            ⚠️ ⚠️ ⚠️ ⚠️ ⚠️  See the Muter error log above this line  ⚠️ ⚠️ ⚠️ ⚠️ ⚠️
//
//            If you feel like this is a bug, or want help figuring out what could be happening, please open an issue at
//            https://github.com/muter-mutation-testing/muter/issues
//
//            """)
//            exit(1)
//    }

} else {
    print("Muter requires macOS 10.13 or higher")
    exit(1)
}
