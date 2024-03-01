protocol ProgressBarPrinter {
    mutating func display(_ progressBar: ProgressBar)
}

struct ProgressBarTerminalPrinter: ProgressBarPrinter {
    var lastPrintedTime = 0.0

    init() {
        // the cursor is moved up before printing the progress bar.
        // have to move the cursor down one line initially.
        print("")
    }

    mutating func display(_ progressBar: ProgressBar) {
        let currentTime = getTimeOfDay()
        if currentTime - lastPrintedTime > 0.1 || progressBar.element == progressBar.count {
            print("\u{1B}[1A\u{1B}[K\(progressBar.value)")
            lastPrintedTime = currentTime
        }
    }
}

// MARK: - ProgressBar

struct ProgressBar {
    var isEmpty: Bool { count <= 0 }
    private(set) var element = 1
    let startTime = getTimeOfDay()

    let count: Int
    let configuration: [ProgressElementType]?

    static var defaultConfiguration: [ProgressElementType] = [
        ProgressIndex(),
        ProgressBarLine(),
        ProgressTimeEstimates(),
    ]

    var printer: ProgressBarPrinter

    var value: String {
        let configuration = configuration ?? ProgressBar.defaultConfiguration
        let values = configuration.map { $0.value(self) }
        return values.joined(separator: " ")
    }

    init(count: Int, configuration: [ProgressElementType]? = nil, printer: ProgressBarPrinter? = nil) {
        self.count = count
        self.configuration = configuration
        self.printer = printer ?? ProgressBarTerminalPrinter()
    }

    mutating func next() {
        guard element <= count else {
            return
        }
        let anotherSelf = self
        printer.display(anotherSelf)
        element += 1
    }

    mutating func setValue(_ index: Int) {
        guard index <= count && index >= 0 else {
            return
        }
        element = index
        let anotherSelf = self
        printer.display(anotherSelf)
    }

}

// MARK: - GeneratorType

struct ProgressGenerator<G: IteratorProtocol>: IteratorProtocol {
    var source: G
    var progressBar: ProgressBar

    init(source: G, count: Int, configuration: [ProgressElementType]? = nil, printer: ProgressBarPrinter? = nil) {
        self.source = source
        progressBar = ProgressBar(count: count, configuration: configuration, printer: printer)
    }

    mutating func next() -> G.Element? {
        progressBar.next()
        return source.next()
    }
}

// MARK: - SequenceType

struct Progress<G: Sequence>: Sequence {
    let generator: G
    let configuration: [ProgressElementType]?
    let printer: ProgressBarPrinter?

    init(_ generator: G, configuration: [ProgressElementType]? = nil, printer: ProgressBarPrinter? = nil) {
        self.generator = generator
        self.configuration = configuration
        self.printer = printer
    }

    func makeIterator() -> ProgressGenerator<G.Iterator> {
        let count = generator.underestimatedCount
        return ProgressGenerator(
            source: generator.makeIterator(),
            count: count,
            configuration: configuration,
            printer: printer
        )
    }
}
