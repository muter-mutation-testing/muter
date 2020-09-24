prefix ?= /usr/local
bindir = $(prefix)/bin
libdir = $(prefix)/lib

builddir = $(shell ./Scripts/builddir.sh)

build:
	xcodebuild -scheme muter -configuration Debug > /dev/null 2>&1

build-release:
	xcodebuild -scheme muter -configuration Release > /dev/null 2>&1

release:
	./Scripts/shipIt.sh $(VERSION)

install: build-release
	builddir = $(shell ./Scripts/builddir.sh "Release")
	install -d "$(bindir)"
	install "$(builddir)/muter" "$(bindir)"

uninstall:
	rm -f "$(bindir)/muter"

run: build
	$(builddir)/muter

test: build
	xcodebuild -scheme muter -only-testing:muterCoreTests test
	
acceptance-test: build
	./AcceptanceTests/runAcceptanceTests.sh

regression-test: build
	./RegressionTests/runRegressionTests.sh

mutation-test: clean
	muter

.PHONY: build test run install uninstall release
