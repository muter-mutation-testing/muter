import Foundation

let coverage = CommandLine.arguments[1]

struct Target: Decodable {
    let name: String
    let lineCoverage: Double
}

let targets = try! JSONDecoder().decode([Target].self, from: coverage.data(using: .utf8)!)
let muterCore = targets.first { $0.name == "muterCore.framework" }

let lineCoverage = muterCore!.lineCoverage * 100.0

let rounded = Int(lineCoverage)
var color = "red"
switch rounded {
case 91...Int.max: color = "brightgreen"
case 76...90: color = "green"
case 61...75: color = "yellowgreen"
case 41...60: color = "yellow"
default: color = "red"
}

print("""
    {
      "color":"\(color)",
      "label":"coverage",
      "message":"\(String(format: "%.2f", lineCoverage))%",
      "schemaVersion":1
    }
    """)