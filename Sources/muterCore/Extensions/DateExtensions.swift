import Foundation

typealias DateFormat = String
extension Date {
    
    var dateTime: String {
        return string(from: "yyyy-MMM-dd-HH-mm")
    }
    
    private func string(from format: DateFormat) -> String {
        let formatter = Date.formatter(from: format)
        return formatter.string(from: self)
    }
    
    private static func formatter(from format: DateFormat) -> DateFormatter {
        let key = "com.muter.dateformatter.\(TimeZone.current.description).\(format)"
        let thread = Thread.current
        if let formatter = thread.threadDictionary[key] as? DateFormatter,
            let copy = formatter.copy() as? DateFormatter {
            return copy
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = format
        thread.threadDictionary[key] = formatter
        
        return formatter
    }
}
