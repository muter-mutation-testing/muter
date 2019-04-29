import Rainbow

public enum MuterError: Error {
    case configurationError
}

extension MuterError: CustomStringConvertible {
    public var description: String {
        
        switch self {
        case .configurationError:
            return """
            Muter was unable to parse your configuration file.
            
            Either you ran Muter from the wrong directory, or your muter.conf.json file is corrupted or missing.
            
            You can run \("muter init".bold) to generate or regenerate a configuration file.
            
            If you feel this is a bug, or want help figuring out what could be happening, please open an issue at
            https://github.com/SeanROlszewski/muter/issues
            """
            
        }
        
    }
    
}
