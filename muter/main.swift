import Darwin
import Commandant
import muterCore

let registry = CommandRegistry<MuterError>()
registry
    .register(InitCommand())
    .register(RunCommand())
    .register(HelpCommand(registry: registry))
    .main(defaultVerb: RunCommand().verb) { (error) in
        print("""
                
            ⚠️ ⚠️ ⚠️ ⚠️ ⚠️  Muter has encountered an error  ⚠️ ⚠️ ⚠️ ⚠️ ⚠️
            \(error)
            

            ⚠️ ⚠️ ⚠️ ⚠️ ⚠️  See the Muter error log above this line  ⚠️ ⚠️ ⚠️ ⚠️ ⚠️
            
            If you feel like this is a bug, or want help figuring out what could be happening, please open an issue at
            https://github.com/muter-mutation-testing/muter/issues
                
            """)
        exit(1)
    }
