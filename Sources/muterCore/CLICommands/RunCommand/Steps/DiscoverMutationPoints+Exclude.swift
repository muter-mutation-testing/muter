//
//  DiscoverMutationPoints+Exclude.swift
//  muterCore
//
//  Created by Uriah Eisenstein on 06/01/2020.
//

// This file is intended to include all of the code related to excluding specific mutation points, for use by struct DiscoverMutationPoints.

import Foundation
import struct SwiftSyntax.AbsolutePosition

let muterSkipMarker = "muter:skip"

struct ExclusionPoint {
    let mutationOperatorId: MutationOperator.Id?
    let filePath: String
    let line: Int
}

extension DiscoverMutationPoints {
    func loadMutationPointsToExclude(inFilesAt filePaths: [String]) -> [ExclusionPoint] {
        let launchPath = "/usr/bin/fgrep"
        let args: [String] = ["-Hn", muterSkipMarker] + filePaths   // -H shows the filename, -n shows the line number
        guard let output = shell(launchPath: launchPath, arguments: args) else {
            return []
        }
        return output.split(separator: "\n").compactMap {
            // fgrep -Hn result format is <filename>:<line number>: <source line>
            let components = $0.split(separator: ":", maxSplits: 3)
            guard components.count >= 2, let path = components.first, let line = Int(components[1]) else {
                return nil
            }
            return ExclusionPoint(mutationOperatorId: nil,  // TODO: Get the real mutation operator, if specified
                filePath: String(path),
                line: line)
        }
    }
}

// Source: https://stackoverflow.com/questions/48376150/how-do-i-run-shell-command-in-swift
func shell(launchPath path: String, arguments args: [String]) -> String? {
    let task = Process()
    task.launchPath = path
    task.arguments = args

    let pipe = Pipe()
    task.standardOutput = pipe
//    task.standardError = pipe // Output errors to console
    task.launch()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)
    task.waitUntilExit()

    return output
}

extension MutationPoint {
    func matchesByLine(_ exclusionPoint: ExclusionPoint) -> Bool {
        return self.filePath == exclusionPoint.filePath
            && (self.mutationOperatorId == exclusionPoint.mutationOperatorId || exclusionPoint.mutationOperatorId == nil)
            && self.position.line == exclusionPoint.line
    }
}
