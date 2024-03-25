protocol ProgressElementType {
    func value(_ progressBar: ProgressBar) -> String
}

/// the progress bar element e.g. "[----------------------        ]"
struct ProgressBarLine: ProgressElementType {
    let barLength: Int

    init(barLength: Int = 30) {
        self.barLength = barLength
    }

    func value(_ progressBar: ProgressBar) -> String {
        var completedBarElements = 0
        if progressBar.isEmpty {
            completedBarElements = barLength
        } else {
            completedBarElements = Int(Double(barLength) * (Double(progressBar.element) / Double(progressBar.count)))
        }

        var barArray = [String](repeating: "-", count: completedBarElements)
        barArray += [String](repeating: " ", count: barLength - completedBarElements)
        return "[" + barArray.joined(separator: "") + "]"
    }
}

/// the index element e.g. "2 of 3"
struct ProgressIndex: ProgressElementType {
    init() {}

    func value(_ progressBar: ProgressBar) -> String {
        "\(progressBar.element) of \(progressBar.count)"
    }
}

/// the percentage element e.g. "90.0%"
struct ProgressPercent: ProgressElementType {
    let decimalPlaces: Int

    init(decimalPlaces: Int = 0) {
        self.decimalPlaces = decimalPlaces
    }

    func value(_ progressBar: ProgressBar) -> String {
        var percentDone = 100.0
        if !progressBar.isEmpty {
            percentDone = Double(progressBar.element) / Double(progressBar.count) * 100
        }
        return "\(percentDone.format(decimalPlaces))%"
    }
}

/// the time estimates e.g. "ETA: 00:00:02 (at 1.00 it/s)"
struct ProgressTimeEstimates: ProgressElementType {
    init() {}

    func value(_ progressBar: ProgressBar) -> String {
        let totalTime = getTimeOfDay() - progressBar.startTime

        var itemsPerSecond = 0.0
        var estimatedTimeRemaining = 0.0
        if progressBar.element > 0 {
            itemsPerSecond = Double(progressBar.element) / totalTime
            estimatedTimeRemaining = Double(progressBar.count - progressBar.element) / itemsPerSecond
        }

        let estimatedTimeRemainingString = formatDuration(estimatedTimeRemaining)

        return "ETA: \(estimatedTimeRemainingString) (at \(itemsPerSecond.format(2))) it/s)"
    }

    fileprivate func formatDuration(_ duration: Double) -> String {
        let duration = Int(duration)
        let seconds = Double(duration % 60)
        let minutes = Double((duration / 60) % 60)
        let hours = Double(duration / 3600)
        return "\(hours.format(0, minimumIntegerPartLength: 2)):\(minutes.format(0, minimumIntegerPartLength: 2)):\(seconds.format(0, minimumIntegerPartLength: 2))"
    }
}

/// an arbitrary string that can be added to the progress bar.
struct ProgressString: ProgressElementType {
    let string: String

    init(string: String) {
        self.string = string
    }

    func value(_: ProgressBar) -> String {
        string
    }
}
