# Muter
### Automated mutation testing for Swift
## What is Mutation Testing?
From [Wikipedia](https://en.wikipedia.org/wiki/Mutation_testing):

> **Mutation testing** is used to design new software tests and evaluate the quality of existing software tests. Mutation testing involves modifying a program in small ways. Each mutated version is called a **mutant** and tests detect and reject mutants by causing the behavior of the original version to differ from the mutant. This is called **killing the mutant**. Test suites are **measured by the percentage of mutants that they kill**. New tests can be designed to kill additional mutants. 

> Mutants are based on well-defined **mutation operators** that either mimic typical programming errors (such as using the wrong operator or variable name) or force the creation of valuable tests (such as dividing each expression by zero). The **purpose is to help the tester develop effective tests or locate weaknesses in the test data** used for the program or in sections of the code that are seldom or never accessed during execution. Mutation testing is a form of **white-box testing**.

## What Is Muter?
Muter is a [mutation testing](https://en.wikipedia.org/wiki/Mutation_testing) utility that is used to help you determine the quality of your test suite.
Specifically, it can help you:
- find gaps in fault/defect coverage from your test suite by identifying missing groups of tests, assertions/expectations, or test cases from your test suite
- determine if you are writing meaningful and effective assertions/expectations that withstand different code than what the test was originally written against
- assess how many tests fail as a result of one code change

With Muter, you can make sure your test suite is meeting all your requirements, fails meaningfully and clearly, and remains stable in the face of unexpected or accidental code changes. 

## How Does It Work?
Instead of leveraging the bugs already present in the code, Muter will add new ones. The bugs introduced by Muter are called **mutants**. 

 By introducing mutants randomly, it can strengthen your code and shine a light on potential weakness that you were unaware existed.

**NOTE**: Muter will always clean up after itself, so there's no need worry about leftover bugs. Muter always backs code up prior to making modifications to it. 

### Mutation Score
A **mutation score** is provided at the end of every run of Muter, which is the ratio of how many mutants were introduced that your test suite caught versus the total number that were introduced.

`mutation score = number of mutants killed / total number of mutants`

For example, if your test suite caught 50 mutants of the 75 introduced by Muter, your score would be 66. A well-engineered test suite should strive to be as close to 100 as possible.

## Installation
Muter is available through homebrew. Run the following command to install Muter:

`brew install seanrolszewski/formulae/muter`

## Setup
### Muter's Configuration
You will need to create a configuration file named `muter.conf.json` in the root directory of the project you're mutation testing. To make this easy, you can run `muter init` in the root directory of your project.

The configuration looks something like this:
```
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
    "blacklist": ["AppDelegate.swift"]
}
```
### Configuration Options
- `executable` - the fully qualified path to the program which can run your test suite 
- `arguments` - any command line arguments the executable needs to run your test suite 
- `blacklist` - a list of paths, file extensions, or names you want Muter to ignore. By default, Muter ignores files or paths containing the following phrases:
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

**NOTE**: Muter uses a substring match to determine if something should be excluded.

For examples of configuration files, check out the `muter.conf.json` in the root directory of this repository, as well as the `muter.conf.json` inside the `ExampleApp` directory.

## Running Muter
Running Muter is easy! Once you've created your configuration, simply run `muter` from either the root directory or a subdirectory of the project you're mutation testing. Muter will take it from there. :)

## Limitations
- Currently, Muter is in open beta. It only change `==` operators into `!=` operators. Further mutations will be released at a later date.
- Running Muter can be a lengthy process, so be sure to allocate enough time for the test to finish.

## Best Practices
- Commit your `muter.conf.json`
- Ensure you run Muter with no uncommitted changes. If Muter fails to finish, there’s a potential for the bugs it introduced to your code to be left behind.
- Because Muter can take a while to run, it is recommend to exclude UI or journey tests from your test suite. We recommend creating a separate schemes or targets for mutation testing. However, you should feel free to run these kinds of tests if you're okay with the longer feedback cycle.
- Don’t be dogmatic about your mutation score - in practice, 100/100 is often times not possible.

## FAQ
**What platforms does Muter support?**

Muter supports any platform that runs using `xcodebuild`, which includes iOS, macOS, tvOS, and watchOS. Prior to its first release, Muter was tested on multiple iOS and macOS codebases. 

**Does Muter support UI test suites?**

Yes! However, these can be very lengthy test suites, and mutation testing can take a long time. I recommend you start using Muter only on your unit tests. Once you have a feel for interpreting mutation scores, you can then ease into incorporating your longer running tests.

**Is Muter self-hosted?**

Yes! Very early on I made the decision to make sure that Muter was able to provide insight into the development of Muter and its test suite. After all, since Muter is providing a form of automated testing, it must be as thorough and robust as possible. :P

**This is all pretty cool, but I'm nervous about running this on my own code. I mean, you're putting bugs into my work, and how do I know you're not stealing my source code?**

This is an understandable concern. If you would like to get a feel for what mutation testing is like, and how Muter performs it, I recommend cloning this repository, installing Muter, and then running Muter on the included example project and Muter itself.

Additionally, because Muter is parsing, analyzing, and modifying your source code, a decision was made to give it no network access - Muter collects no analytics, and never phones home. Feel free to look at it's source code if you have concerns about this, or open an issue if you would like to have a discussion. 

And lastly, make sure you look at and follow Muter's best practices to ensure the best possible experience while using Muter.