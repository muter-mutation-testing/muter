import Foundation
import Rainbow

func printHeader() {
    print(
        """
        
        \("""
         _____       _
        |     | _ _ | |_  ___  ___
        | | | || | ||  _|| -_||  _|
        |_|_|_||___||_|  |___||_|
        """.green)
        
        Automated mutation testing for Swift
        
        You are running version \("\(version)".bold)
        
        Want help? Have suggestions? Want to get involved?
         ↳ https://github.com/muter-mutation-testing/muter/issues
        +------------------------------------------------+
        
        """)
}

func printMessage(_ message: String) {
    print("+-----------------+")
    print(message)
}
