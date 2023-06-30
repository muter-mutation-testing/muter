import TestingExtensions
import XCTest

final class DictionaryExtensionTests: XCTestCase {
    func test_filtersOutKeysNotMatchingAPredicateOnAnyNestedDictionaries() {
        let dictionary: [String: Any] = [
            "key": "value",
            "toss": [5],
            "so": [
                ["toss": "", "keep": ""],
                ["toss": "", "keep": ""]
            ],
            "anotherKey": [
                "keep": 5,
                "yup": ["toss": "yuppppp"],
                "toss": "get wrekt, son",
            ] as [String: Any]
        ]

        let results = dictionary.recursivelyFiltered(includingKeysMatching: { $0 != "toss" })

        XCTAssertTrue(results.keys.sorted().elementsEqual(["anotherKey", "key", "so"]))

        let array = results["so"] as? [[String: Any]]
        XCTAssertEqual(array?.count, 2)
        XCTAssertTrue(array?.first?.keys.sorted().elementsEqual(["keep"]))
        XCTAssertTrue(array?.last?.keys.sorted().elementsEqual(["keep"]))

        let nestedDictionary = results["anotherKey"] as? [String: Any]
        XCTAssertTrue(nestedDictionary?.keys.sorted().elementsEqual(["keep", "yup"]))

        let anotherNestedDictionary = nestedDictionary?["yup"] as? [String: Any]
        XCTAssertTrue(anotherNestedDictionary?.keys.isEmpty)
    }
}
