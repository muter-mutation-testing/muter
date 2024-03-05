import ArgumentParser
import Foundation

struct RunArguments: ParsableArguments {
    @Option(
        name: [.customShort("c"), .customLong("configuration")],
        help: "The path to the muter configuration file."
    )
    var configurationURL: URL?

    @Flag(
        name: [.customLong("skip-coverage")],
        help: "Skips the step in which Muter runs your project in order to filter out files without coverage."
    )
    var skipCoverage: Bool = false

    @Flag(
        name: [.customLong("skip-update-check")],
        help: "Skips the step in which Muter checks for newer versions."
    )
    var skipUpdateCheck: Bool = false
}
