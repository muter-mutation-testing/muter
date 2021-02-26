import Foundation

final class JsonReporter: Reporter {
    func mutationTestingFinished(mutationTestOutcome outcome: MutationTestOutcome) {
        print(report(from: outcome))
    }
    
    func report(from outcome: MutationTestOutcome) -> String {
        let report = MuterTestReport(from: outcome)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        guard let encoded = try? encoder.encode(report),
            let json = String(data: encoded, encoding: .utf8) else {
                return ""
        }
        
        return json
    }
}
