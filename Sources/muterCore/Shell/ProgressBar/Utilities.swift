#if os(Linux)
import Glibc
#else
import Darwin.C
#endif

func getTimeOfDay() -> Double {
    var tv = timeval()
    gettimeofday(&tv, nil)
    return Double(tv.tv_sec) + Double(tv.tv_usec) / 1000000
}

extension Double {
    func format(_ decimalPartLength: Int, minimumIntegerPartLength: Int = 0) -> String {
        let value = String(self)
        let components = value
            .split { $0 == "." }
            .map { String($0) }

        var integerPart = components.first ?? "0"

        let missingLeadingZeros = minimumIntegerPartLength - integerPart.count
        if missingLeadingZeros > 0 {
            integerPart = stringWithZeros(missingLeadingZeros) + integerPart
        }

        if decimalPartLength == 0 {
            return integerPart
        }

        var decimalPlaces = components.last?.substringWithRange(0, end: decimalPartLength) ?? "0"
        let missingPlaceCount = decimalPartLength - decimalPlaces.count
        decimalPlaces += stringWithZeros(missingPlaceCount)

        return "\(integerPart).\(decimalPlaces)"
    }

    private func stringWithZeros(_ count: Int) -> String {
        Array(repeating: "0", count: count).joined(separator: "")
    }
}

extension String {
    func substringWithRange(_ start: Int, end: Int) -> String {
        var end = end
        if start < 0 || start > count {
            return ""
        } else if end < 0 || end > count {
            end = count
        }
        let range = index(startIndex, offsetBy: start) ..< index(startIndex, offsetBy: end)
        return String(self[range])
    }
}
