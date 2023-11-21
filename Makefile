prefix ?= /usr/local
bindir = $(prefix)/bin
libdir = $(prefix)/lib

repodir = $(shell pwd)
builddir = $(repodir)/.build

build:
	@swift package clean
	@swift build -c debug $(flags)

build-release: 
	@python ./Scripts/install_build.py "build_release"

project:
	@xed .

release: 
	@./Scripts/shipIt.sh $(version)

install:
	@python ./Scripts/install_build.py "install"

uninstall:
	@rm -rf "$(bindir)/muter"

clean:
	@rm -rf .build

run: build
	@$(builddir)/debug/muter

test:
	@swift test --filter 'muterTests'
	
acceptance-test: build
	@./AcceptanceTests/runAcceptanceTests.sh

regression-test: build
	@./RegressionTests/runRegressionTests.sh

mutation-test: clean
	muter

# ci

ci-regression-test: build
	@./Scripts/ci/regression/run_regression_tests.sh

ci-test: build
	@./Scripts/ci/pull\ request/run_unit_test.sh
	@./Scripts/ci/pull\ request/extract_coverage.sh

.PHONY: build clean test run install uninstall release
