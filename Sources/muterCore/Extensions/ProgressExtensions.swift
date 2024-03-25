import Foundation
import Rainbow

class SimpleTimeEstimate: ProgressElementType {
    private let initialEstimate: TimeInterval
    private var lastTime: Date = .init()

    init(initialEstimate: TimeInterval) {
        self.initialEstimate = initialEstimate
    }

    func value(_ progressBar: ProgressBar) -> String {
        let timeSinceLastInvocation = Date()
        let timePerItem = DateInterval(start: lastTime, end: timeSinceLastInvocation).duration

        let estimatedTimeRemaining = progressBar.element == 0 ?
            initialEstimate :
            Double(progressBar.count - progressBar.element) * timePerItem

        lastTime = Date()

        let remainingMinutes = Int(ceil(estimatedTimeRemaining / 60))

        let formattedRemainingMinutes = "\(remainingMinutes) \(remainingMinutes == 1 ? "minutes" : "minute")"

        return "ETC: \(formattedRemainingMinutes)"
    }
}

struct ProgressOneIndexed: ProgressElementType {
    init() {}

    func value(_ progressBar: ProgressBar) -> String {
        let index = progressBar.element + 1 > progressBar.count ?
            progressBar.element :
            progressBar.element + 1
        return "\(index) of \(progressBar.count)"
    }
}

struct ColoredProgressBarLine: ProgressElementType {
    let barLength: Int

    private func colorMap(_ completedBarElements: Int) -> Color {
        let interval = barLength / 4
        switch completedBarElements {
        case 0 ... interval: return Color.magenta
        case (interval + 1) ... (2 * interval): return Color.lightRed
        case (2 * interval + 1) ... (3 * interval): return Color.yellow
        default: return Color.green
        }
    }

    init(barLength: Int = 30) {
        self.barLength = barLength
    }

    func value(_ progressBar: ProgressBar) -> String {
        var completedBarElements = 0
        if progressBar.isEmpty {
            completedBarElements = barLength
        } else {
            let progress = Double(barLength) * Double(progressBar.element)
            completedBarElements = Int(progress / Double(progressBar.count))
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
    @Dependency(\.logger)
    private var logger: Logger

    init(numberOfLines: Int) {
        self.numberOfLines = numberOfLines
        // the cursor is moved up before printing the progress bar.
        // have to move the cursor down one line initially.
        logger.print("")
    }

    mutating func display(_ progressBar: ProgressBar) {
        let currentTime = getTimeOfDay()
        if currentTime - lastPrintedTime > 0.1 || progressBar.element == progressBar.count {
            let lines = "\u{1B}[1A\u{1B}".repeated(numberOfLines)
            logger.print("\(lines)[K\(progressBar.value)")
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
