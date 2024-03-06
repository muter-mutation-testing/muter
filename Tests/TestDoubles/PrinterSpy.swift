import Foundation
@testable import muterCore

final class PrinterSpy {
    private(set) var linesPassed: [String] = []

    func print(_ line: String) {
        linesPassed.append(line)
    }
}
