prefix ?= /usr/local
bindir = $(prefix)/bin
libdir = $(prefix)/lib

# pluck out "CONFIGURATION_BUILD_DIR" and then extract just the file path
# -o prints only the matched (non-empty) parts
# -E uses extended regular expression
# -i ignores case distinctions
builddir = $(shell xcodebuild -configuration Release -showBuildSettings | grep "CONFIGURATION_BUILD_DIR" | grep -oEi "\/.*")
build:
	xcodebuild -scheme muter -configuration Debug > /dev/null 2>&1

build-release:
	xcodebuild -scheme muter -configuration Release > /dev/null 2>&1

release:
	./Scripts/shipIt.sh $(VERSION)

install: build-release
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
