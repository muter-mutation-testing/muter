prefix ?= /usr/local
bindir = $(prefix)/bin
libdir = $(prefix)/lib

repodir = $(shell pwd)
builddir = $(repodir)/.build

build:
	@swift package clean
	@swift build -c debug $(flags)

build-release: 
	@swift build -c release --product muter --disable-sandbox

project:
	@xed .

release: 
	@./Scripts/shipIt.sh $(version)

install: build-release
	@install -d "$(bindir)" "$(libdir)"
	@install "$(builddir)/release/muter" "$(bindir)"

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
