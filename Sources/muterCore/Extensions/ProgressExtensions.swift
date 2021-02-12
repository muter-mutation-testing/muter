import Progress
import Foundation
import Rainbow

public class SimpleTimeEstimate: ProgressElementType {
    private let initialEstimate: TimeInterval
    private var lastTime: Date = Date()
    
    public init(initialEstimate: TimeInterval) {
        self.initialEstimate = initialEstimate
    }
    
    public func value(_ progressBar: ProgressBar) -> String {
        let timeSinceLastInvocation = Date()
        let timePerItem = DateInterval(start: lastTime, end: timeSinceLastInvocation).duration
        
        let estimatedTimeRemaining = progressBar.index == 0 ?
            initialEstimate :
            Double(progressBar.count - progressBar.index) * timePerItem
        
        lastTime = Date()
        
        return "ETC: \(Int(ceil(estimatedTimeRemaining/60))) minute(s)"
    }
}

public struct ProgressOneIndexed: ProgressElementType {
    public init() {}
    
    public func value(_ progressBar: ProgressBar) -> String {
        let index = progressBar.index + 1 > progressBar.count ?
            progressBar.index :
            progressBar.index + 1
        return "\(index) of \(progressBar.count)"
    }
}

public struct ColoredProgressBarLine: ProgressElementType {
    let barLength: Int
    
    private func colorMap(_ completedBarElements: Int) -> Color {
        let interval = barLength / 4
        switch completedBarElements {
        case (0...(interval)): return Color.magenta
        case ((interval+1)...(2*interval)): return Color.lightRed
        case ((2*interval+1)...(3*interval)): return Color.yellow
        default: return Color.green
        }
    }
    
    public init(barLength: Int = 30) {
        self.barLength = barLength
    }
    
    public func value(_ progressBar: ProgressBar) -> String {
        var completedBarElements = 0
        if progressBar.count == 0 {
            completedBarElements = barLength
        } else {
            completedBarElements = Int(Double(barLength) * (Double(progressBar.index) / Double(progressBar.count)))
        }
        
        let color = colorMap(completedBarElements)
        var barArray = [String](repeating: "-".applyingColor(color), count: completedBarElements)
        barArray += [String](repeating: " ", count: barLength - completedBarElements)
        return "[" + barArray.joined(separator: "") + "]"
    }
}
struct ProgressBarMultilineTerminalPrinter: ProgressBarPrinter {
    var lastPrintedTime = 0.0
    private let numberOfLines: Int
    init(numberOfLines: Int) {
        self.numberOfLines = numberOfLines
        // the cursor is moved up before printing the progress bar.
        // have to move the cursor down one line initially.
        print("")
    }
    

    mutating func display(_ progressBar: ProgressBar) {
        let currentTime = getTimeOfDay()
        if currentTime - lastPrintedTime > 0.1 || progressBar.index == progressBar.count {
            let lines = "\u{1B}[1A\u{1B}".repeated(numberOfLines)
            print("\(lines)[K\(progressBar.value)")
            lastPrintedTime = currentTime
        }
    }
}

private extension ProgressBarMultilineTerminalPrinter {
    func getTimeOfDay() -> Double {
        var tv = timeval()
        gettimeofday(&tv, nil)
        return Double(tv.tv_sec) + Double(tv.tv_usec) / 1000000
    }
}
