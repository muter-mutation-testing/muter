# Mutation Operators
Muter uses **mutation operators** to generate mutants in your source code. This is the list of currently available mutation operators.

## Negate Conditionals
The negate conditionals operator will invert conditional operators in your code based on this table:

Original Operator | Negated Operator
------------------|-----------------
`==`|`!=`
`!=`|`==`
`>=`|`<=`
`<=`|`>=`
`>`|`<`
`<`|`>`

The purpose of this operator is to highlight how your tests respond to changes in branching logic. A well-engineered test suite will be able to fail clearly in response to code taking a different branch than it expected.

### Mutating an equality check
```swift
if myValue == 50 {
    // something happens here
}
```

becomes

```swift
if myValue != 50 {
    // something happens here
}
```

## Change Logical Connector
The change logical connector operator will change conditional operators in your code based on this table:

Original Operator | Changed Operator
------------------|-----------------
`&&`|`||`
`||`|`&&`

The purpose of this operator is to highlight how your tests respond to changes in logic. A well-engineered test suite will be able to fail clearly in response to different logical constraints.

### Mutating a Logical AND
```swift
func isValidPassword(_ text: String, _ repeatedText: String) -> Bool {
    let meetsMinimumLength = text.count >= 8
    let passwordsMatch = repeatedText == text
    return meetsMinimumLength && passwordsMatch
}
```

becomes

```swift
func isValidPassword(_ text: String, _ repeatedText: String) -> Bool {
    let meetsMinimumLength = text.count >= 8
    let passwordsMatch = repeatedText == text
    return meetsMinimumLength || passwordsMatch
}
```

## Remove Side Effects 
The Remove Side Effects operator will remove code it determines is causing a side effect. It will determine your code is causing a side effect based on a few rules:

* A line contains a function call which is explicitly discarding a return result
* A line contains a function call and doesn't save the result of the function call into a named variable or constant (i.e. a line implicitly discards a return result or doesn't produce one)
* A line does not contain a call to `print`, `exit`, `fatalError`, `abort`, or any function listed in `muter.conf.json` under the `excludeCalls` key.

The purpose of this operator is to highlight how your tests respond to the absence of expected side effects.

### Mutating an explicitly discarded return result

```swift
func initialize() {
    _ = self.view
    view.results = self.results
}
```

becomes

```swift
func initialize() {
    view.results = self.results
}
```


### Mutating a void function call

```swift
func update(email: String, for userId: String) {
    var userRecord = record(for: userId)
    userRecord.email = email
    database.persist(userRecord)
}
```

becomes

```swift
func update(email: String, for userId: String) {
    var userRecord = record(for: userId)
    userRecord.email = email
}
```
