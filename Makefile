prefix ?= /usr/local
bindir = $(prefix)/bin
libdir = $(prefix)/lib

buildDir = $(shell xcodebuild -configuration Release -showBuildSettings | grep "CONFIGURATION_BUILD_DIR" | grep -oEi "\/.*")
build:
	xcodebuild -scheme muter -configuration Debug > /dev/null 2>&1

build-release:
	xcodebuild -scheme muter -configuration Release > /dev/null 2>&1

release:
	./Scripts/shipIt.sh $(VERSION)

install: build-release
	install -d "$(bindir)"
	install "$(buildDir)/muter" "$(bindir)"

uninstall:
	rm -f "$(bindir)/muter"

run: build
	$(buildDir)/muter

test: build
	xcodebuild -scheme muter -only-testing:muterCoreTests test
	
acceptance-test: build
	./AcceptanceTests/runAcceptanceTests.sh

regression-test: build
	./RegressionTests/runRegressionTests.sh

mutation-test: clean
	muter

.PHONY: build test run install uninstall release
