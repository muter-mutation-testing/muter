import Darwin
import Commandant
import muterCore

if #available(OSX 10.13, *) {
    
    let registry = CommandRegistry<MuterError>()
    registry
        .register(InitCommand())
        .register(RunCommand())
        .register(HelpCommand(registry: registry))
        .main(defaultVerb: RunCommand().verb) { (error) in
            print("\(error)")
            exit(1)
    }

} else {
    print("Muter requires macOS 10.13 or higher")
    exit(1)
}
