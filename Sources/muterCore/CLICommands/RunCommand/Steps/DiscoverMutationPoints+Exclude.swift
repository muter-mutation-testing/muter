//
//  DiscoverMutationPoints+Exclude.swift
//  muterCore
//
//  Created by Uriah Eisenstein on 06/01/2020.
//

// This file is intended to include all of the code related to excluding specific mutation points, for use by struct DiscoverMutationPoints.

import Foundation
import SwiftSyntax

let muterSkipMarker = "muter:skip"

// Currently supports only line comments (in block comments, would need to detect in which actual line the skip marker appears - and if it isn't the first or last line, it won't contain code anyway)
class ExcludedMutationPointsDetector: SyntaxVisitor {

    private(set) var excludedLines: [Int] = []
    
    override func visitPre(_ node: Syntax) {
        let markedForExclusion = node.leadingTrivia?.contains {
            if case .lineComment(let commentText) = $0 {
                return commentText.contains(muterSkipMarker)
            } else {
                return false
            }
        }
        if markedForExclusion == true {
            excludedLines.append(node.position.line)
        }
    }
}
