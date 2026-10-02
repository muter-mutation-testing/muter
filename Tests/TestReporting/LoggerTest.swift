import Foundation
@testable import muterCore
import TestingExtensions

final class LoggerTests: MuterTestCase {
    private let sut = Logger()

    func test_printer() throws {
        sut.launched()
        sut.updateCheckStarted()
        sut.updateCheckFinished(newVersion: "1.0.0")
        sut.projectCopyStarted()
        sut.projectCopyFinished(destinationPath: "/path/to/destination")
        sut.projectCoverageDiscoveryStarted()
        sut.projectCoverageDiscoveryFinished(success: true)
        sut.sourceFileDiscoveryStarted()
        sut.sourceFileDiscoveryFinished(sourceFileCandidates: ["file0.swift", "file1.swift", "file2.swift"])
        sut.mutationsDiscoveryStarted()
        try sut.mutationsDiscoveryFinished(mutations: [makeSchemataMapping()])
        sut.mutationTestingStarted()
        sut.newMutationTestLogAvailable(
            mutationTestLog: .make(
                timePerBuildTestCycle: 50,
                remainingMutationPointsCount: 5
            )
        )
        sut.newMutationTestLogAvailable(
            mutationTestLog: .make(
                mutationPoint: .make()
            )
        )
        sut.testPlanFileCreated(atPath: "/path/to/test-plan")
        sut.configurationFileCreated(atPath: "/path/to/config-file")
        sut.muterMutationTestPlanLoaded()
        sut.mutationTestingFinished(
            report: "... muter report ... ",
            reportPath: "/path/to/report",
            isExportingReport: true,
            didSaveReport: true
        )

        AssertSnapshot(printer.linesPassed.joined(separator: "\n"))
    }

    func test_projectCopySkippedVanishedFiles_listsUpToFivePaths() {
        sut.projectCopySkippedVanishedFiles((1 ... 7).map { "/p/f\($0).lock" })

        XCTAssertEqual(printer.linesPassed, [
            """
            ⚠️ Skipped 7 file(s) that disappeared while your project was being copied:
              /p/f1.lock
              /p/f2.lock
              /p/f3.lock
              /p/f4.lock
              /p/f5.lock
              … and 2 more
            """,
        ])
    }

    private func makeSchemataMapping() throws -> SchemataMutationMapping {
        try SchemataMutationMapping.make(
            filePath: "/some/path",
            (
                source: "func bar() { }",
                schemata: [
                    .make(
                        filePath: "/tmp/project/file.swift",
                        mutationOperatorId: .ror,
                        syntaxMutation: "",
                        position: .firstPosition,
                        snapshot: .null
                    ),
                ]
            )
        )
    }
}
