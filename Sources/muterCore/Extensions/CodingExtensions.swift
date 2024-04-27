//
//  CodingExtensions.swift
//
//
//  Created by Annalise Mariottini on 4/12/24.
//

import Foundation

extension KeyedDecodingContainerProtocol {
    func decode<A: Decodable>(_ type: A.Type, default: A, forKey key: KeyedDecodingContainer<Key>.Key) -> A {
        (try? decode(A.self, forKey: key)) ?? `default`
    }
}
