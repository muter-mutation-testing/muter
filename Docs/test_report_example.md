# Example Test Report

```
*******************************
Muter finished running!

--------------------------
Applied Mutation Operators
--------------------------

These are all of the ways that Muter introduced changes into your code.

In total, Muter applied 19 mutation operators.

File                               Position                Applied Mutation Operator   Mutation Test Result
----                               --------                -------------------------   --------------------
AbsolutePositionExtensions.swift   Line: 10, Column: 24    Negate Conditionals         passed
AbsolutePositionExtensions.swift   Line: 11, Column: 55    Negate Conditionals         passed
NegateConditionalsMutation.swift   Line: 21, Column: 43    Side Effects                passed
NegateConditionalsMutation.swift   Line: 43, Column: 25    Negate Conditionals         passed
SideEffectsMutation.swift          Line: 20, Column: 97    Negate Conditionals         passed
SideEffectsMutation.swift          Line: 25, Column: 12    Negate Conditionals         passed
SideEffectsMutation.swift          Line: 62, Column: 72    Negate Conditionals         passed
SideEffectsMutation.swift          Line: 71, Column: 45    Negate Conditionals         passed
CLITable.swift                     Line: 36, Column: 16    Negate Conditionals         passed
CLITable.swift                     Line: 52, Column: 21    Negate Conditionals         passed
mutationDiscovery.swift            Line: 41, Column: 27    Negate Conditionals         passed
mutationDiscovery.swift            Line: 41, Column: 70    Negate Conditionals         passed
subCommands.swift                  Line: 19, Column: 65    Side Effects                failed
subCommands.swift                  Line: 26, Column: 68    Side Effects                failed
subCommands.swift                  Line: 42, Column: 40    Side Effects                passed
subCommands.swift                  Line: 48, Column: 43    Negate Conditionals         passed
testReportGeneration.swift         Line: 78, Column: 61    Negate Conditionals         passed
testReportGeneration.swift         Line: 95, Column: 15    Negate Conditionals         passed
testReportGeneration.swift         Line: 101, Column: 31   Negate Conditionals         failed



--------------------
Mutation Test Scores
--------------------

Mutation Score of Test Suite (higher is better): 84/100

File                               # of Applied Mutation Operators   Mutation Score
----                               -------------------------------   --------------
AbsolutePositionExtensions.swift   2                                 100
NegateConditionalsMutation.swift   2                                 100
SideEffectsMutation.swift          4                                 100
CLITable.swift                     2                                 100
mutationDiscovery.swift            2                                 100
subCommands.swift                  4                                 50
testReportGeneration.swift         3                                 66
