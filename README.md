# Muter
### Automated [mutation testing](https://en.wikipedia.org/wiki/Mutation_testing) for Swift inspired by [Stryker](https://github.com/stryker-mutator/stryker), [PITest](https://github.com/hcoles/pitest), and [Mull](https://github.com/mull-project/mull).

## What Is Muter?
Muter is a mutation testing utility that is used to help you determine the quality of your test suite.

With Muter, you can make sure your test suite is meeting all your requirements, fails meaningfully and clearly, and remains stable in the face of unexpected or accidental code changes.

If you're interested in checking out more about mutation testing, you can check out [this link](https://en.wikipedia.org/wiki/Mutation_testing).

## Why Should I Use This?

Muter can strengthen your test suite and shine a light on weaknesses that you were unaware existed. It does this by generating a mutation score (expanded on below), which will show you both the areas you may want to improve in your test suite, as well as the areas that are performing well. 

Specifically, a mutation score can help you:
- Find gaps in fault coverage from your test suite by identifying missing groups of tests, assertions, or test cases from your test suite
- Determine if you are writing meaningful and effective assertions that withstand different code than what the test was originally written against
- Assess how many tests fail as a result of one code change

## How Does It Work?
Muter will introduce changes into your sourcecode based on the logic contained in your app. The changes introduced by Muter are called **mutants** which it generates using **mutation operators**.

You can view the list of available mutation operators [here](https://github.com/SeanROlszewski/muter/blob/master/Docs/mutation_operators.md). 

**NOTE**: Muter does all of its work on a complete copy of your codebase, so it's not possible for it to accidentally leave anything behind.

### Mutation Score
A **mutation score** is provided at the end of every run of Muter. The score is the ratio of the number of mutants your test suite caught versus the total number of mutants introduced.

`mutation score = number of mutants killed / total number of mutants`

For example, if your test suite caught 50 mutants of the 75 introduced by Muter, your score would be 66. A well-engineered test suite should strive to be as close to 100 as possible.

Muter not only provides a mutation score for your entire test suite, but it also generates individual scores for the files it has mutated.

If you're curious about how a mutation score is different than test code coverage, then check out [this document](https://github.com/SeanROlszewski/muter/blob/master/Docs/mutation_score_vs_test_code_coverage.md).

## Example Test Report
There's an example of [the test report that Muter generates](https://github.com/SeanROlszewski/muter/blob/master/Docs/test_report_example.md) hosted in this repository.

Check out this example to fmailiarize yourself with what a report looks like.

## Installation
Muter is available through [Homebrew](https://brew.sh/). Run the following command to install Muter:

`brew install seanrolszewski/formulae/muter`

## Setup
### Muter's Configuration
You will need to create a configuration file named `muter.conf.json` in the root directory of the project you're mutation testing. To make this easy, you can run `muter init` in the root directory of your project. After running the `init` command, fill in the configuration with the options listed below.

### Configuration Options
- `executable` - the absolute path to the program which can run your test suite (like `xcodebuild`, `swift`, `fastlane`, `make`, etc.)
- `arguments` - any command line arguments the executable needs to run your test suite
- `exclude` - a list of paths, file extensions, or names you want Muter to ignore. By default, Muter ignores files or paths containing the following phrases:
    * `.build`
    * `.framework`
    * `.swiftdep`
    * `.swiftmodule`
    * `Build`
    * `Carthage`
    * `muter_tmp`
    * `Pods`
    * `Spec`
    * `Test`

    The `exclude` option is optional.

**NOTE**: Muter uses a substring match to determine if something should be excluded.

Below is an example pulled directly from the `ExampleApp` directory.
The configuration file will end up looking something like this:
```json
{
    "executable": "/usr/bin/xcodebuild",
    "arguments": [
        "-project",
        "ExampleApp.xcodeproj",
        "-scheme",
        "ExampleApp",
        "-sdk",
        "iphonesimulator",
        "-destination",
        "platform=iOS Simulator,name=iPhone 8",
        "test"
    ],
    "exclude": ["AppDelegate.swift"]
}
```

Check out the `muter.conf.json` in the root directory of this repository for another example.


## Running Muter
Running Muter is easy. Once you've created your configuration file simply run `muter` in your terminal from any directory of the project you're mutation testing. Muter will take it from there. 

## Limitations
- Muter assumes you always put spaces around your operators. For example, it expects an equality check to look like

    `a == b (Muter will mutate this)`

    not like:

    `a==b (Muter won't mutate this)`
- Muter assumes you aren't putting multiple expressions on one line (and I have the opinion you shouldn't be doing this anyway). Basically, if you aren't using semicolons in your code then Muter shouldn't have an issue mutating it.

## Best Practices
- Commit your `muter.conf.json`
- Disable or relax linting rules that would cause a build error as a consequence of a code change not matching your project 's style. Muter operates on your source code then rebuilds it, and the change it introduces could trigger your linter if it's part of your build process.
- Running Muter can be a lengthy process, so be sure to allocate enough time for the test to finish.
- Because Muter can take a while to run, it is recommend to exclude UI or journey tests from your test suite. We recommend creating a separate schemes or targets for mutation testing. However, you should feel free to run these kinds of tests if you're okay with the longer feedback cycle.
- Don’t be dogmatic about your mutation score - in practice, 100/100 is often times not possible.

## FAQ
**What platforms does Muter support?**

Muter supports any platform that compiles and tests using `xcodebuild`, which includes iOS, macOS, tvOS, and watchOS. 

Muter can only run on macOS 10.13 or higher.

**Does Muter support UI test suites?**

Yes! However, these can be very lengthy test suites, and mutation testing can take a long time. I recommend you start using Muter only on your unit tests. Once you have a feel for interpreting mutation scores, you can then ease into incorporating your longer running tests.

**Does Muter support Objective-C?**

No, not at this time. Objective-C support will come at a later time. Until then, Muter only supports Swift code. Any bridging code that's written in Swift, but ultimately calls down to Objective-C, is compatible with Muter.

**Is Muter self-hosted?**

Yes! Very early on I made the decision to make sure that Muter was able to provide insight into its development and test suite. After all, since Muter is providing a form of automated testing, it must be as thorough and robust as possible. :P

**This is all pretty cool, but I'm nervous about running this on my own code. I mean, you're putting bugs into my work, and how do I know you're not stealing my source code?**

This is an understandable concern. If you would like to get a feel for what mutation testing is like, and how Muter performs it, I recommend cloning this repository, installing Muter, and then running Muter on the included example project and Muter itself.

Additionally, because Muter is parsing, analyzing, and modifying your source code, a decision was made to give it no network access - Muter collects no analytics, and never phones home. Feel free to look at its source code if you have concerns about this, or open an issue if you would like to have a discussion.

And lastly, make sure you look at and follow Muter's best practices to ensure the best possible experience while using Muter.
