import Foundation

enum Reporter: Equatable {
    case plainText
    case json
    case xcode
    
    func generateReport(from outcomes: [MutationTestOutcome], footerOnly: Bool = false) -> String {
        switch self {
        case .plainText:
            return textReport(from: outcomes)
        case .json:
            return jsonReport(from: outcomes)
        case .xcode:
            return xcodeReport(from: outcomes, footerOnly: footerOnly)
        }
    }
}

extension Reporter {
    init(shouldOutputJson: Bool, shouldOutputXcode: Bool) {
        if shouldOutputJson {
            self = .json
        }
        else if shouldOutputXcode {
            self = .xcode
        }
        else {
            self = .plainText
        }
    }
}



}
