import Rainbow

public enum MuterError: Error, Equatable {
    case configurationParsingError(reason: String)
    case projectCopyFailed(reason: String)
    case unableToCreateSwapFileDirectory(reason: String)
    case noSourceFilesDiscovered
    case noSourceFilesOnExclusiveList
    case noMutationPointsDiscovered
    case mutationTestingAborted(reason: MutationTestingAbortReason)
    case removeTempDirectoryFailed(reason: String)
}

extension MuterError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .configurationParsingError(let reason):
            return """
            Muter was unable to parse your configuration file.
            
            This is often caused from running Muter from the wrong directory, or having a corrupted or missing muter.conf.json
            
            You can run \("muter init".bold) to generate or regenerate a configuration file.
            
            ******************
            FileManager Error:
            \(reason)
            ******************
            """
        case .projectCopyFailed(let reason):
            return """
            Muter was unable to create a temporary directory, or was unable to copy your project into a temporary directory, and cannot continue.
            
            This is unusual. Try running Muter again to see if that fixes the issue.
            Alternatively, try clearing all temp files from your temp directory by restarting your computer.
            
            Please include the following in the bug report:
            *********************
            FileManager error: \(reason)
            """
        case .unableToCreateSwapFileDirectory(let reason):
            return """
            Muter was unable to create a swap file directory, which is a necessary component of it's mutation testing strategy.
            
            This is unusual. Try running Muter again to see if that fixes the issue. Alternatively, try clearing all temp files from your temp directory by restarting your computer.
            
            Please include the following in the bug report:
            *********************
            FileManager error: \(reason)
            """
        case .noSourceFilesDiscovered:
            return """
            Muter wasn't able to discover any code it could mutation test.
            
            This is likely caused by misconfiguring Muter, usually by excluding a directory that contains your code.
            """
        case .noSourceFilesOnExclusiveList:
            return """
            Muter wasn't able to discover on list provided by the `files-to-mutate` flag.
            
            Please check the list of files and try again.
            """
        case .noMutationPointsDiscovered:
            return """
            Muter wasn't able to discover any code it could mutation test.
            
            This is likely caused by misconfiguring Muter, usually by excluding a directory that contains your code.
            """
        case .mutationTestingAborted(let reason):
            return """
            \(reason)
            """
        case .removeTempDirectoryFailed(reason: let reason):
            return """
            Muter wasn't able to remove temporary directory.
            
            ******************
            FileManager Error: \(reason)
            """
        }
    }
}
