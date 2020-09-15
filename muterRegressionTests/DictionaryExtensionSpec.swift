import Quick
import Nimble
import TestingExtensions

class DictionaryExtensionSpec: QuickSpec {
    override func spec() {
        describe("Dictionary<String, Any>.recursivelyFiltered") {
            it("filters out keys not matching a predicate on any nested dictionaries") {
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
                    ]
                ]
                
                let results = dictionary.recursivelyFiltered(includingKeysMatching: { $0 != "toss" })
                
                expect(results.keys.sorted().elementsEqual(["anotherKey", "key", "so"])) == true
                
                let array = results["so"] as? [[String: Any]]
                expect(array).to(haveCount(2))
                expect(array?.first?.keys.sorted().elementsEqual(["keep"])) == true
                expect(array?.last?.keys.sorted().elementsEqual(["keep"])) == true

                let nestedDictionary = results["anotherKey"] as? [String: Any]
                expect(nestedDictionary?.keys.sorted().elementsEqual(["keep", "yup"])) == true
                
                let anotherNestedDictionary = nestedDictionary?["yup"] as? [String: Any]
                expect(anotherNestedDictionary?.keys).to(beEmpty())
            }
        }
    }
}
