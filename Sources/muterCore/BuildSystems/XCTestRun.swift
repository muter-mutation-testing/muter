import Foundation

struct XCTestRun: Equatable {
    private let plist: [String: AnyHashable]
    
    init(_ plist: [String: AnyHashable] = [:]) {
        self.plist = plist
    }
    
    func updateEnvironmentVariable(
        setting key: String
    ) -> [String: AnyHashable] {
        var copy = plist
        let environmentVariablesKey = "EnvironmentVariables"
        
        for (plistEntry, plistValue) in copy {
            if var testConfiguration = plistValue as? [String: AnyHashable],
               testConfiguration.keys.contains(environmentVariablesKey),
               var allEnvironmentVariables = testConfiguration[environmentVariablesKey] as? [String: AnyHashable] {
                allEnvironmentVariables[key] = "YES"
                allEnvironmentVariables[isMuterRunningKey] = isMuterRunningValue
                
                testConfiguration[environmentVariablesKey] = allEnvironmentVariables
                
                copy[plistEntry] = testConfiguration
            }
        }
        
        return copy
    }
}
