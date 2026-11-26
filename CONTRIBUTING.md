# Contributing to Muter

## Getting a Feature to Work On
The three pinned issues within our issue tracker are the highest priority issues to work on. If all of these are taken, or if these don't feel like something you would want to work on, then feel free to open an issue stating you'd like to work on something and we'll point you to an issue you could pick up. We're constantly reprioritizing our backlog, so the best way to find out what to work on is to ask!

## Submitting a Feature Request
We're always open to feature requests. We may not be able to accommodate it in the next release, but it's super valuable for us to understand what you want.

To request a feature, simply open an issue.

When requesting a feature, please be descriptive in what you are asking for - examples are super helpful, and links to prior art are also very helpful. We also think it's very important to understand any pain you are experiencing by not having a feature. Based on this information, we can look at other users' feature requests and determine where it falls in our priorities.

## Setting Up the Project

### Requirements
- macOS 13 or later.
- Xcode 26 or later. CI builds with Xcode 26; local development also works with Xcode 27.
- An iOS Simulator runtime, for the acceptance tests.

### Getting the Code
Fork the repository, then clone your fork:

```sh
git clone https://github.com/<your-user>/muter.git
cd muter
```

The `homebrew-formulae` folder is a Git submodule with Muter's Homebrew formula. You need it only to make a release, so you can skip `git submodule update --init`.

### Building
Muter is a Swift package. Build it from the command line:

```sh
swift build
```

To work in Xcode, open the package:

```sh
make project
```

This runs `xed .`, which opens `Package.swift` in Xcode.

### Formatting and Linting
The repository has a `.swiftformat` file for [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) and a `.swiftlint.yml` file for [SwiftLint](https://github.com/realm/SwiftLint). If you have these tools installed, run them on the files you change before you open a pull request.

## Submitting a Pull Request
When working on a feature or bug, fork Muter's repository and work on your own branch locally. Once you're ready to have it merged back in, open a pull request and tag whomever you've had conversation with about the issue.

Prefer rebasing over merging `master` into your PR branch if you need to bring it up-to-date. We're happy to work through any merge conflicts with you that you have difficulty understanding.

## Your First Pull Request
1. Pick an issue, or open one, and say in it that you'd like to work on it.
2. Create a branch with a name that describes the change, for example `fix-coverage-on-xcode-26`.
3. Write a test that fails without your change. See [Testing Philosophy](#testing-philosophy).
4. Make the change, and run the unit tests with `make test` until they pass.
5. If your change affects which mutants Muter finds or how it runs them, also run `make acceptance-test` and `make regression-test`. If their snapshots change, check each change before you record the new snapshots (see [Snapshots](#snapshots)).
6. Push the branch to your fork, and open a pull request against `master`. Describe what changed, why, and how you tested it.
7. CI runs the unit, acceptance and regression tests on your pull request. Fix what fails, and answer review comments.

## Testing Philosophy
Given that Muter is intended to perform a form of automated testing, it's extremely important that it has its own test suite which is very thorough and rigorous. It has very high code coverage, a very high mutation score, and has been entirely test-driven. It's important that any new code added to the code base doesn't significantly and adversely affect these metrics. We also feel it's important (though not required) for any contributor to practice test-driven development when working on Muter's codebase.

Because of the above, any pull requests which are adding features or bug fixes and omit new or updated tests won't be merged. We'll provide feedback on the tests that you should add, as well as how you can effectively backfill them without compromising the tests' quality. 

We want to avoid having this conversation, so if you feel uncertain or nervous about how to test something, feel free to ask on your issue. After all, the contributors working on this project are giant testing nerds, and we would love to help you get better at writing tests! :D

### Running Muter's Tests

#### Unit Tests
To run Muter's unit tests from the command line:

```make test```

You can also run them in Xcode, after `make project`. Run them often as you develop a feature or a bug fix.

#### Acceptance and Regression Tests
Run these tests from the command line. They depend on files that a run of Muter creates, so they fail if you run them in Xcode without that run.

Run the acceptance tests with:

```make acceptance-test```

The acceptance tests run Muter on the example projects in `Repositories`, including an iOS app, so they need an iOS Simulator. `muter init` picks an available iPhone simulator on the newest iOS runtime.

Run the regression tests with:

```make regression-test```

The regression tests run Muter on three real projects (BonMot, FFCParserCombinator and ProjectWithConcurrency) and compare each report with a snapshot.

Run the acceptance tests often if you're making a change which impacts a user's workflow or journey through Muter's interface. Run the regression tests often if your change affects which mutants Muter finds, how it runs them, or its test report. At a bare minimum, run both prior to making a pull request.

Both of these test suites are lengthy (about 5 to 10 minutes each). Budget your time accordingly, perhaps to coincide with a bathroom or tea break. :)

#### Snapshots
Many tests compare output with a snapshot file in a `__Snapshots__` folder. When your change is meant to change the output:

1. Delete the snapshot file.
2. Run the test once. It records a new snapshot and fails.
3. Run the test again. It now passes.
4. Read the diff of the snapshot before you commit it.

The regression snapshots record a killed mutant as `killed`, whether a test failed or the test runner crashed, because which of the two the test runner reports first depends on the Xcode version.

#### Debugging Coverage
Muter skips mutants in code that no test runs. If Muter cannot read function coverage, it prints a warning that names the step that failed. To see each step's result, set `MUTER_DEBUG_COVERAGE`:

```sh
MUTER_DEBUG_COVERAGE=1 muter
```

#### Continuous Integration
CI runs on Bitrise, with the configuration in `bitrise.yml`. A pull request runs the unit tests, the acceptance tests and the regression tests. To change CI, change `bitrise.yml` in a pull request.

#### Mutation Tests
It's possible (and encouraged!) to run Muter on itself. To do this with the version of the code you've been working on, run:

```
make install prefix=$(brew --prefix)
make mutation-test
```

The `mutation-test` action expects Muter to be on your `PATH`, so if you've installed Muter via homebrew, it's possible for you to use that version as well if you would like. Which version it will use when you have both depends on how you have your `PATH` variable set up. 

**Pro Tip:** If you're looking for an easy way to identify the between the two of them, we recommend updating `version.swift` with a development version string. However, don't commit this change.
