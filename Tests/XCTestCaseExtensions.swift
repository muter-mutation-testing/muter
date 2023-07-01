@testable import muterCore
import XCTest

class MuterTestCase: XCTestCase {
    private(set) var notificationCenter: NotificationCenter = .init()
    private(set) var fileManager = FileManagerSpy()
    private(set) var ioDelegate = MutationTestingDelegateSpy()
    private(set) var prepareCode = SourceCodePreparationSub()
    private(set) var process = ProcessSpy()
    private(set) var flushStandardOut = FlushHandlerSpy()

    override func setUp() {
        super.setUp()

        setup()
    }

    override func setUpWithError() throws {
        try super.setUpWithError()

        setup()
    }

    override func setUp(completion: @escaping (Error?) -> Void) {
        super.setUp(completion: completion)

        setup()
    }

    private func setup() {
        current = World(
            notificationCenter: notificationCenter,
            fileManager: fileManager,
            flushStandardOut: flushStandardOut.flush,
            ioDelegate: ioDelegate,
            process: { self.process },
            prepareCode: prepareCode.prepare
        )
    }
}

public extension XCTestCase {
    var productsDirectory: URL {
        #if os(macOS)
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        fatalError("couldn't find the products directory")
        #else
        return Bundle.main.bundleURL
        #endif
    }

    var rootTestDirectory: String {
        String(
            URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .withoutScheme()
        )
    }

    var fixturesDirectory: String { "\(rootTestDirectory)/fixtures" }
    var configurationPath: String { "\(fixturesDirectory)/\(MuterConfiguration.fileNameWithExtension)" }
    var mutationExamplesDirectory: String { "\(fixturesDirectory)/MutationExamples" }
}
