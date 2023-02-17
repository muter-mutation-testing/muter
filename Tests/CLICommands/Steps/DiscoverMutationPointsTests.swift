//import XCTest
//import SwiftSyntax
//
//@testable import muterCore
//
//final class DiscoverMutationPointsTests: XCTestCase {
//    private let state = RunCommandState()
//    private let sut = DiscoverMutationPoints()
//    
//    func test_whenItDiscoversMutationPoints_thenAddThemToParsedSourceCode() throws {
//        state.sourceFileCandidates = [
//            "\(fixturesDirectory)/sampleForDiscoveringMutations.swift",
//            "\(fixturesDirectory)/sample With Spaces For Discovering Mutations.swift",
//        ]
//        
//        let filePath1 = "\(fixturesDirectory)/sampleForDiscoveringMutations.swift"
//        let filePath2 = "\(fixturesDirectory)/sample With Spaces For Discovering Mutations.swift"
//
//        let result = try XCTUnwrap(sut.run(with: state).get())
//
//        let stateChangesIncludesParsedSourceCode = result.contains {
//            let expectedFilePaths = Set([filePath2, filePath1])
//            let expectedSourceCode = Set([
//                sourceCode(fromFileAt: filePath1)!.code.description,
//                sourceCode(fromFileAt: filePath2)!.code.description,
//            ])
//
//            if case .sourceCodeParsed(let parsedSourceCode) = $0 {
//                let actualFilePaths = Set(parsedSourceCode.map { $0.key })
//                let actualSourceCode = Set(parsedSourceCode.map { $0.value.description })
//                return (expectedSourceCode, expectedFilePaths) == (actualSourceCode, actualFilePaths)
//            }
//            return false
//        }
//
//        let stateChangesIncludesMutationPoints = result.contains {
//            if case .mutationPointsDiscovered(let actualMutationPoints) = $0 {
//                return actualMutationPoints == [
//                    MutationPoint(mutationOperatorId: .ror,
//                                  filePath: filePath1,
//                                  position: MutationPosition(utf8Offset: 84, line: 3, column: 19)),
//                    MutationPoint(mutationOperatorId: .ror,
//                                  filePath: filePath1,
//                                  position: MutationPosition(utf8Offset: 106, line: 4, column: 18)),
//                    MutationPoint(mutationOperatorId: .ternaryOperator,
//                                  filePath: filePath1,
//                                  position: MutationPosition(utf8Offset: 134, line: 4, column: 46)),
//                    MutationPoint(mutationOperatorId: .removeSideEffects,
//                                  filePath: filePath2,
//                                  position: MutationPosition(utf8Offset: 154, line: 6, column: 42)),
//                    MutationPoint(mutationOperatorId: .removeSideEffects,
//                                  filePath: filePath2,
//                                  position: MutationPosition(utf8Offset: 177, line: 7, column: 23)),
//                ]
//            }
//            return false
//        }
//
//        XCTAssertTrue(stateChangesIncludesParsedSourceCode)
//        XCTAssertTrue(stateChangesIncludesMutationPoints)
//    }
//    
//    func test_shouldIgnoreSkippedLines() throws {
//        let samplePath = "\(fixturesDirectory)/sample with mutations marked for skipping.swift"
//        state.sourceFileCandidates = [samplePath]
//        
//        let result = try XCTUnwrap(sut.run(with: state).get())
//        
//        let stateChangesIncludesOnlyUnskippedMutationPoints = result.contains {
//            if case .mutationPointsDiscovered(let actualMutationPoints) = $0 {
//                return actualMutationPoints == [
//                    MutationPoint(mutationOperatorId: .removeSideEffects,
//                                  filePath: samplePath,
//                                  position: MutationPosition(utf8Offset: 53, line: 3, column: 42)),
//                ]
//            }
//            return false
//        }
//
//        XCTAssertTrue(stateChangesIncludesOnlyUnskippedMutationPoints)
//    }
//    
//    func test_shouldIgnoreUknownOperators() {
//        state.sourceFileCandidates = [
//            "\(fixturesDirectory)/sourceWithoutMutableCode.swift",
//        ]
//        
//        let result = sut.run(with: state)
//        
//        XCTAssertEqual(result, .failure(.noMutationPointsDiscovered))
//    }
//}
