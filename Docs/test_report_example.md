# Example Test Report

```
+-------------------+
Muter finished running!

--------------------------
Applied Mutation Operators
--------------------------

These are all of the ways that Muter introduced changes into your code.

In total, Muter applied 14 mutation operators.

File                                  Applied Mutation Operator   Mutation Test Result
----                                  -------------------------   --------------------
InitCommand.swift:25                  Remove Side Effects         mutant killed (test failure)
RunCommand.swift:27                   Remove Side Effects         mutant killed (test failure)
RunCommandIODelegate.swift:77         Negate Conditionals         mutant survived
RunCommandIODelegate.swift:92         Remove Side Effects         mutant survived
AbsolutePositionExtensions.swift:5    Negate Conditionals         mutant killed (test failure)
NegateConditionalsOperator.swift:18   Negate Conditionals         mutant killed (test failure)
NegateConditionalsOperator.swift:22   Remove Side Effects         mutant killed (test failure)
NegateConditionalsOperator.swift:44   Negate Conditionals         mutant killed (test failure)
RemoveSideEffectsOperator.swift:20    Negate Conditionals         mutant killed (test failure)
RemoveSideEffectsOperator.swift:25    Negate Conditionals         mutant killed (test failure)
RemoveSideEffectsOperator.swift:62    Negate Conditionals         mutant killed (test failure)
RemoveSideEffectsOperator.swift:71    Negate Conditionals         mutant killed (test failure)
mutationDiscovery.swift:41            Negate Conditionals         mutant killed (test failure)
mutationDiscovery.swift:41            Negate Conditionals         mutant survived


--------------------
Mutation Test Scores
--------------------

These are the mutation scores for your test suite, as well as the files that had mutants introduced into them.

Mutation scores ignore build errors.

Of the 14 mutants introduced into your code, your test suite killed 11.
Mutation Score of Test Suite: 78%

File                               # of Applied Mutation Operators   Mutation Score
----                               -------------------------------   --------------
InitCommand.swift                  1                                 100
RunCommand.swift                   1                                 100
RunCommandIODelegate.swift         2                                 0
AbsolutePositionExtensions.swift   1                                 100
NegateConditionalsOperator.swift   3                                 100
RemoveSideEffectsOperator.swift    4                                 100
mutationDiscovery.swift            2                                 50
```
