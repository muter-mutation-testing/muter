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
```
if myValue == 50 {
    // something happens here
}
```

becomes

```
if myValue != 50 {
    // something happens here
}
```

## Remove Side Effects 
The Remove Side Effects operator will remove code it determines is causing a side effect. It will determine your code is causing a side effect based on a few rules:

* A line contains a function call which is explicitly discarding a return result
* A line contains a function call and doesn't save the result of the function call into a named variable or constant (i.e. a line implicitly discards a return result or doesn't produce one)
* A line does not contain a call to `print`, `exit`, `fatalError`, or `abort`

The purpose of this operator is to highlight how your tests respond to the absence of expected side effects. 

### Mutating an explicitly discarded return result

```
func initialize() {
    _ = self.view
    view.results = self.results
}
```

becomes

```
func initialize() {
    view.results = self.results
}
```


### Mutating a void function call

```
func update(email: String, for userId: String) {
    var userRecord = record(for: userId)
    userRecord.email = email
    database.persist(userRecord)
}
```

becomes

```
func update(email: String, for userId: String) {
    var userRecord = record(for: userId)
    userRecord.email = email
}
```