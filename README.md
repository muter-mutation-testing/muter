# Muter 
[![Swift 5 support](https://img.shields.io/badge/swift-5-ED523F.svg?style=flat)](https://swift.org/download/) 
[![Build Status](https://app.bitrise.io/app/84b65f2a76ed7616/status.svg?token=ZtVl3AxP2ybPB17Ug1wIJQ)](https://app.bitrise.io/app/84b65f2a76ed7616)
![Mutation score is 75](https://img.shields.io/badge/mutation%20score-75-blue?style=flat)

### Automated [mutation testing](https://en.wikipedia.org/wiki/Mutation_testing) for Swift inspired by [Stryker](https://github.com/stryker-mutator/stryker), [PITest](https://github.com/hcoles/pitest), and [Mull](https://github.com/mull-project/mull).

#### Muter can be run within Xcode
Use this mode to rapidly diagnose areas where you can begin improving your test code
 
![Muter running inside Xcode](https://i.imgur.com/ApxFrFc.png) 

#### Muter can be run from the command line
Use this mode to get detailed information about the health and quality of your entire test suite

![Muter running from the commandline](Docs/muter-cli-output-v2.gif)


#### Muter can be run in your CI
Use this script to easily mutation test your projects incrementally, enabling you to have per-commit updates on how code changes impact the quality of your test suite. Seemlessly connect the output of this CI step into your dashboard or communication channel of choice, or use it as a starting point for thinking about how you want to incrementally test your code.

```muter --files-to-mutate $(echo \"$(git diff --name-only HEAD HEAD~1 | tr '\n' ',')\")```  

## Table of Contents
### Introduction
1. [What Is Muter?](#what-is-muter)
1. [Why Should I Use This?](#why-should-i-use-this)
1. [How Does It Work?](#how-does-it-work)
### Getting Started
1. [Installation](#installation)
1. [Setup](#setup)
1. [Running Muter](#running-muter)
1. [Assumptions](#assumptions)
1. [Best Practices](#best-practices)
1. [FAQs](#faqs)

## What Is Muter?
Muter is a mutation testing utility that is used to help you determine the quality of your test suite.

With Muter, you can make sure your test suite is meeting all your requirements, fails meaningfully and clearly, and remains stable in the face of unexpected or accidental code changes.

If you're interested in checking out more about mutation testing, you can check out [this link](https://en.wikipedia.org/wiki/Mutation_testing).

## Why Should I Use This?

Muter can strengthen your test suite and shine a light on weaknesses that you were unaware existed. It does this by generating a **mutation score** (expanded on below), which will show you both the areas you may want to improve in your test suite, as well as the areas that are performing well. 

Specifically, a mutation score can help you:
- Find gaps in fault coverage from your test suite by identifying missing groups of tests, assertions, or test cases from your test suite
- Determine if you are writing meaningful and effective assertions that withstand different code than what the test was originally written against
- Assess how many tests fail as a result of one code change

## How Does It Work?
Muter will introduce changes into your source code based on the logic contained in your app. The changes introduced by Muter are called **mutants** which it generates using **mutation operators**.

You can view the list of available mutation operators [here](https://github.com/muter-mutation-testing/muter/blob/master/Docs/mutation_operators.md). 

**NOTE**: Muter does all of its work on a complete copy of your codebase, so it's not possible for it to accidentally leave anything behind.

### Mutation Score
A **mutation score** is provided at the end of every run of Muter. The score is the ratio of the number of mutants your test suite killed versus the total number of mutants introduced.

`mutation score = number of mutants killed / total number of mutants`

For example, if your test suite killed 50 mutants of the 75 introduced by Muter, your score would be 67%. A well-engineered test suite should strive to be as close to 100% as possible.

Muter not only provides a mutation score for your entire test suite, but it also generates individual scores for the files it has mutated.

If you're curious about how a mutation score is different than test code coverage, then check out [this document](https://github.com/muter-mutation-testing/muter/blob/master/Docs/mutation_score_vs_test_code_coverage.md).

## Installation
Muter is available through [Homebrew](https://brew.sh/). Run the following command to install Muter:

`brew install muter-mutation-testing/formulae/muter`

### Building From Source
You can build Muter from source, and get the latest set of features/improvements, by running the following: 

```
git clone https://github.com/muter-mutation-testing/muter.git
cd muter
make install
```

If you've already installed Muter via homebrew, this will install over it. If you've done this, and want to go back to the latest version you've downloaded through homebrew, run the following: 

```
make uninstall
brew link muter
```

## Setup
### Muter's Configuration
To get started using Muter, run `muter init` in the root of your project directory. Muter will take its best guess at a configuration that will work for your project. Muter supports generating configurations for the following build systems:
* Xcode Projects & Workspace
* Swift Package Manager

It saves its configuration into a file named `muter.conf.json`, which you should keep in the root directory of your project. You should version control your configuration file as well. 

After running `muter init`, you should look at the generated configuration and ensure that it will run your project. We recommend trying the settings it generates in your terminal, and verifying those commands run your tests.

Should you need to modify any of the options, you can use the list below to understand what each configuration option does.

### Configuration Options
- `executable` - the absolute path to the program which can run your test suite (like `xcodebuild`, `swift`, `fastlane`, `make`, etc.)
- `arguments` - any command line arguments the executable needs to run your test suite
- `exclude` - a list of paths, file extensions, or names you want Muter to ignore. By default, Muter ignores all non-Swift files, and any files or paths containing the following phrases:
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

**NOTE**: Muter uses a substring match to determine if a file should be excluded from mutation testing. You should not use glob expressions (like `**/*Model.swift`) or regex.

Below is an example pulled directly from the `ExampleApp` project.
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

### Xcode Setup
Setting up Muter to run within Xcode is simple. After creating your configuation:

1) **Create a new Aggregate Build Target** in the Xcode project of the codebase you're mutation testing. We suggest calling it "Mutation Test"
2) **Add a run script step** to the newly created aggregate build target.
3) **Add the Muter Xcode command** to the build step:

    ```muter --output-xcode```

## Running Muter

### From the command line

Once you've created your configuration file, simply run `muter` in your terminal from any directory of the project you're mutation testing. Muter will take it from there. 

**Available Subcommands**
```
   help   Display general or command-specific help
   init   Creates the configuration file that Muter uses
   run    Performs mutation testing for the Swift project contained within the current directory
```
Muter defaults to run when you don't specify any subcommands

**Available Flags**
```
   --files-to-mutate    Only mutate a given list of source code files (Supports glob expressions like Sources/**/*.swift)
   --output-json        Output test results to a json file
   --output-xcode       Output test results in a format consumable by an Xcode run script step
```

### Within Xcode
Build (Cmd + B) your aggregate build target and let Muter run. The mutants which survive testing will be called out in the issue navigator. Once the target finishes building, testing has completed.

### Skipping Mutations
You can mark specific lines to skip mutations on, rather than entire files, by adding to them a line comment containing the text `muter:skip` (inspired by a similar feature in Swiftlint). This is mostly useful after the first run, if you conclude that specific uncaught mutants shouldn't be covered by your test suite – e.g. logging-related code, specific lines accessing real network/timers etc. This will prevent Muter from wasting time on testing them on subsequent runs, and reduce the 'noise'.

## Assumptions
- Muter assumes you always put spaces around your operators. For example, it expects an equality check to look like

    `a == b (Muter will mutate this)`

    not like:

    `a==b (Muter won't mutate this)`
- Muter assumes you aren't putting multiple expressions on one line (and we have the opinion you shouldn't be doing this anyway). Basically, if you aren't using semicolons in your code then Muter shouldn't have an issue mutating it.

## Best Practices
- Commit your `muter.conf.json`
- It's possible for Muter to cause compile time warnings. As a result of this, we recommend you don't treat Swift warnings as errors while mutation testing by adding the argument `SWIFT_TREAT_WARNINGS_AS_ERRORS=NO` to your `muter.conf.json` if you're using `xcodebuild`.
- Disable or relax linting rules that would cause a build error as a consequence of a code change not matching your project's style. Muter operates on your source code and then rebuilds it, and the change it introduces could trigger your linter if it's part of your build process.
- Running Muter can be a lengthy process, so be sure to allocate enough time for the test to finish.
- Because Muter can take a while to run, it is recommend to exclude UI or journey tests from your test suite. We recommend creating a separate schemes or targets for mutation testing. However, you should feel free to run these kinds of tests if you're okay with the longer feedback cycle.
- Don’t be dogmatic about your mutation score - in practice, 100% is not always possible.

## Example Test Report
There's an example of [the test report that Muter generates](https://github.com/muter-mutation-testing/muter/blob/master/Docs/test_report_example.md) hosted in this repository.

Check out this example to familiarize yourself with what a report looks like.

## FAQs
**What platforms does Muter support?**

Muter supports any platform that compiles and tests using `xcodebuild`, which includes iOS, macOS, tvOS, and watchOS. 

Muter can run only on macOS 10.13 or higher.

**Does Muter support UI test suites?**

Yes! Muter supports any kind of test target or test suite, provided your application code is written in Swift. 

However, UI test suites can be very lengthy, and mutation testing can take a long time. I recommend you start using Muter only on your unit tests. Once you have a feel for interpreting mutation scores, you can then ease into incorporating your longer-running tests.

**Does Muter support Objective-C?**

No, not at this time. Objective-C support may come at a later time. Until then, Muter only supports Swift code. Any bridging code that's written in Swift, but ultimately calls down to Objective-C, is compatible with Muter.

**Is Muter self-hosted?**

Yes! Very early on I made the decision to make sure that Muter was able to provide insight into its development and test suite. After all, since Muter is providing a form of automated testing, it must be as thorough and robust as possible. :P

**This is all pretty cool, but I'm nervous about running this on my own code. I mean, you're putting bugs into my work, and how do I know you're not stealing my source code?**

This is an understandable concern. If you would like to get a feel for what mutation testing is like, and how Muter performs it, I recommend cloning this repository, installing Muter, and then running Muter on the included example project and Muter itself.

Additionally, because Muter is parsing, analyzing, and modifying your source code, a decision was made to give it no network access - Muter collects no analytics, and never phones home. Feel free to look at its source code if you have concerns about this, or open an issue if you would like to have a discussion.

And lastly, make sure you look at and follow Muter's best practices to ensure the best possible experience while using Muter.
