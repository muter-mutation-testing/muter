# Example Test Report

```
Here's your test report:

--------------------------
Applied Mutation Operators
--------------------------

These are all of the ways that Muter introduced changes into your code.

In total, Muter introduced 54 mutants in 14 files.

File                                           Applied Mutation Operator       Mutation Test Result
----                                           -------------------------       --------------------
ContextualAlternates.swift:63                  RemoveSideEffects               mutant survived
ContextualAlternates.swift:75                  SwapTernary                     mutant killed (test failure)
ContextualAlternates.swift:78                  SwapTernary                     mutant survived
ContextualAlternates.swift:81                  SwapTernary                     mutant survived
FontFeatures.swift:34                          RelationalOperatorReplacement   mutant killed (test failure)
FontFeatures.swift:40                          RelationalOperatorReplacement   mutant killed (test failure)
FontFeatures.swift:47                          RemoveSideEffects               mutant killed (test failure)
NSAttributedString+BonMot.swift:72             ChangeLogicalConnector          mutant survived
StylisticAlternates.swift:204                  RemoveSideEffects               mutant survived
StylisticAlternates.swift:217                  SwapTernary                     mutant survived
StylisticAlternates.swift:220                  SwapTernary                     mutant killed (test failure)
StylisticAlternates.swift:223                  SwapTernary                     mutant survived
StylisticAlternates.swift:226                  SwapTernary                     mutant survived
StylisticAlternates.swift:229                  SwapTernary                     mutant killed (test failure)
StylisticAlternates.swift:232                  SwapTernary                     mutant killed (test failure)
StylisticAlternates.swift:235                  SwapTernary                     mutant survived
StylisticAlternates.swift:238                  SwapTernary                     mutant survived
StylisticAlternates.swift:241                  SwapTernary                     mutant survived
StylisticAlternates.swift:244                  SwapTernary                     mutant survived
StylisticAlternates.swift:247                  SwapTernary                     mutant survived
StylisticAlternates.swift:250                  SwapTernary                     mutant survived
StylisticAlternates.swift:253                  SwapTernary                     mutant survived
StylisticAlternates.swift:256                  SwapTernary                     mutant survived
StylisticAlternates.swift:259                  SwapTernary                     mutant survived
StylisticAlternates.swift:262                  SwapTernary                     mutant survived
StylisticAlternates.swift:265                  SwapTernary                     mutant survived
StylisticAlternates.swift:268                  SwapTernary                     mutant survived
StylisticAlternates.swift:271                  SwapTernary                     mutant survived
StylisticAlternates.swift:274                  SwapTernary                     mutant survived
Tracking.swift:23                              RelationalOperatorReplacement   mutant survived
AdaptableTextContainer.swift:84                RelationalOperatorReplacement   mutant survived
AdaptableTextContainer.swift:94                RemoveSideEffects               mutant survived
AdaptiveStyle.swift:131                        RelationalOperatorReplacement   mutant survived
AdaptiveStyle.swift:131                        SwapTernary                     mutant survived
AdaptiveStyle.swift:133                        RelationalOperatorReplacement   mutant survived
AdaptiveStyle.swift:133                        SwapTernary                     mutant survived
EmbeddedTransformation.swift:50                RelationalOperatorReplacement   mutant survived
NSAttributedString+Adaptive.swift:39           RemoveSideEffects               mutant survived
NSAttributedString+Adaptive.swift:54           RemoveSideEffects               mutant survived
NSAttributedString+Adaptive.swift:55           RemoveSideEffects               mutant survived
StyleableUIElement.swift:200                   RemoveSideEffects               mutant survived
StyleableUIElement.swift:81                    RelationalOperatorReplacement   mutant survived
TextAlignmentConstraint.swift:135              RemoveSideEffects               mutant killed (test failure)
TextAlignmentConstraint.swift:136              RemoveSideEffects               mutant killed (test failure)
TextAlignmentConstraint.swift:146              RemoveSideEffects               mutant survived
TextAlignmentConstraint.swift:147              RemoveSideEffects               mutant survived
TextAlignmentConstraint.swift:148              RemoveSideEffects               mutant survived
TextAlignmentConstraint.swift:178              RelationalOperatorReplacement   mutant survived
TextAlignmentConstraint.swift:183              RemoveSideEffects               mutant survived
UIKit+AdaptableTextContainerSupport.swift:29   RemoveSideEffects               mutant survived
UIKit+AdaptableTextContainerSupport.swift:59   RelationalOperatorReplacement   mutant survived
UIKit+AdaptableTextContainerSupport.swift:66   RemoveSideEffects               mutant survived
UIKit+AdaptableTextContainerSupport.swift:67   RemoveSideEffects               mutant survived
UIKit+Helpers.swift:43                         RelationalOperatorReplacement   mutant survived
Platform.swift:0                               RemoveSideEffects               skipped (no coverage)


--------------------
Mutation Test Scores
--------------------

These are the mutation scores for your test suite, as well as the files that had mutants introduced into them.

Mutation scores ignore build errors.

Of the 54 mutants introduced into your code, your test suite killed 9.
Mutation Score of Test Suite: 16%
Code Coverage of your project: 81%

File                                        # of Introduced Mutants   Mutation Score
----                                        -----------------------   --------------
ContextualAlternates.swift                  4                         25
FontFeatures.swift                          3                         100
NSAttributedString+BonMot.swift             1                         0
StylisticAlternates.swift                   21                        14
Tracking.swift                              1                         0
AdaptableTextContainer.swift                2                         0
AdaptiveStyle.swift                         4                         0
EmbeddedTransformation.swift                1                         0
NSAttributedString+Adaptive.swift           3                         0
StyleableUIElement.swift                    2                         0
TextAlignmentConstraint.swift               7                         28
UIKit+AdaptableTextContainerSupport.swift   4                         0
UIKit+Helpers.swift                         1                         0
Platform.swift                              1                         0
```
