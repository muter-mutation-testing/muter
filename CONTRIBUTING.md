# Contributing to Muter

## Getting a Feature to Work On
The three pinned issues within our issue tracker are the highest priority issues to work on. If all of these are taken, or if these don't feel like something you would want to work on, then feel free to open an issue stating you'd like to work on something and we'll point you to an issue you could pick up. We're constantly reprioritizing our backlog, so the best way to find out what to work on is to ask!

## Submitting a Feature Request
We're always open to feature requests. We may not be able to accommodate it in the next release, but it's super valuable for us to understand what you want.

To request a feature, simply open an issue.

When requesting a feature, please be descriptive in what you are asking for - examples are super helpful, and links to prior art are also very helpful. We also think it's very important to understand any pain you are experiencing by not having a feature. Based on this information, we can look at other users' feature requests and determine where it falls in our priorities.

## Submitting a Pull Request
When working on a feature or bug, fork Muter's repository and work on your own branch locally. Once you're ready to have it merged back in, open a pull request and tag whomever you've had conversation with about the issue.

Prefer rebasing over merging `master` into your PR branch if you need to bring it up-to-date. We're happy to work through any merge conflicts with you that you have difficulty understanding.

## Testing Philosophy
Given that Muter is intended to perform a form of automated testing, it's extremely important that it has its own test suite which is very thorough and rigorous. It has very high code coverage, a very high mutation score, and has been entirely test-driven. It's important that any new code added to the code base doesn't significantly and adversely affect these metrics. We also feel it's important (though not required) for any contributor to practice test-driven development when working on Muter's codebase.

Because of the above, any pull requests which are adding features or bug fixes and omit new or updated tests won't be merged. We'll provide feedback on the tests that you should add, as well as how you can effectively backfill them without compromising the tests' quality. 

We want to avoid having this conversation, so if you feel uncertain or nervous about how to test something, feel free to ask on your issue. After all, the contributors working on this project are giant testing nerds, and we would love to help you get better at writing tests! :D

### Running Muter's Tests

#### Unit Tests
To run Muter's unit tests from the command line:

```make test```

Alternatively, you can generate an xcode project with the command:

```make project```

and then run them from within xcode. These should be run frequently as you're developing a feature or bug fix.

#### Acceptance and Regression Tests
You must run these tests from the commandline as they depend on certain files having been generated from a run of Muter - if you run them from within Xcode, they will likely fail. For these reasons, we recommend you disable the test targets if you are using Xcode to work on a change. 

Additionally, these tests will overwrite any generated Xcode project you may be using as they rely on the project file to run the tests they focus on.

Run the acceptance tests with:

```make acceptance-test```


Run the regression tests with:

```make regression-test```

Run the acceptance tests often if you're making a change which impacts a user's workflow or journey through Muter's interface. Otherwise, you can get away with running them less frequently. At a bare minimum, ensure you run them prior to making a pull request.

Run the regression tests often if you are making changes to Muter's test report. Otherwise, we want you to run them once prior to making a pull request.

Both of these test suites are lengthy (~5 minutes). Budget your time accordingly, perhaps to coincide with a bathroom or tea break. :)

#### Mutation Tests
It's possible (and encouraged!) to run Muter on itself. To do this with the version of the code you've been working on, run:

```
make install prefix=$(brew --prefix)
make mutation-test
```

The `mutation-test` action expects Muter to be on your `PATH`, so if you've installed Muter via homebrew, it's possible for you to use that version as well if you would like. Which version it will use when you have both depends on how you have your `PATH` variable set up. 

**Pro Tip:** If you're looking for an easy way to identify the between the two of them, we recommend updating `version.swift` with a development version string. However, don't commit this change.
