import Foundation

let coverage = CommandLine.arguments[1]
let value = (Double(coverage.replacingOccurrences(of: "%", with: "")) ?? 0).rounded(.toNearestOrAwayFromZero)
let rounded = Int(value)
var color = "red"
switch rounded {
case 91 ... Int.max: color = "brightgreen"
case 76 ... 90: color = "green"
case 61 ... 75: color = "yellowgreen"
case 41 ... 60: color = "yellow"
default: color = "red"
}

print(
    "{\"color\":\"\(color)\",\"label\":\"coverage\",\"message\":\"\(value)\",\"schemaVersion\":1}"
)
