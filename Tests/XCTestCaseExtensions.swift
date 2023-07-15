@testable import muterCore
import TestingExtensions
import XCTest

class MuterTestCase: XCTestCase {
    private(set) var notificationCenter: NotificationCenter = .init()
    private(set) var fileManager = FileManagerSpy()
    private(set) var ioDelegate = MutationTestingDelegateSpy()
    private(set) var prepareCode = SourceCodePreparationSub()
    private(set) var process = ProcessSpy()
    private(set) var flushStandardOut = FlushHandlerSpy()
    private(set) var server = ServerSpy()
    private let fixedNow = DateComponents(
        calendar: .init(identifier: .gregorian),
        year: 2021,
        month: 1,
        day: 20,
        hour: 2,
        minute: 42
    ).date!

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
            prepareCode: prepareCode.prepare,
            server: server,
            now: { self.fixedNow }
        )
    }

    func generateSchemataMappings(
        for source: SourceCodeInfo,
        changes: MutationSourceCodePreparationChange = .null
    ) -> [SchemataMutationMapping] {
        MutationOperator.Id.allCases
            .accumulate(into: []) { newSchemataMappings, mutationOperatorId in
                let visitor = mutationOperatorId.visitor(
                    .init(),
                    source.asSourceFileInfo
                )

                visitor.sourceCodePreparationChange = changes

                visitor.walk(source.code)

                let schemataMapping = visitor.schemataMappings

                if !schemataMapping.isEmpty {
                    return newSchemataMappings + [schemataMapping]
                } else {
                    return newSchemataMappings
                }
            }.mergeByFileName()
    }

    func assertThrowsMuterError(
        _ expression: @autoclosure () async throws -> some Any,
        _ expectedError: MuterError,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        try await assertThrowsMuterError(
            await expression(),
            message(),
            file: file,
            line: line
        ) { error in
            XCTAssertEqual(error, expectedError, file: file, line: line)
        }
    }

    func assertThrowsMuterError(
        _ expression: @autoclosure () async throws -> some Any,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line,
        _ errorHandler: (MuterError) throws -> Void
    ) async {
        try await AssertThrowsError(
            await expression(),
            message(),
            file: file,
            line: line
        ) { error in
            if let muterError = error as? MuterError {
                try errorHandler(muterError)
            } else {
                XCTFail("Expected \(MuterError.self), got \(error)", file: file, line: line)
            }
        }
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
