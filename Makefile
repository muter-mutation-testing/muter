prefix ?= /usr/local
bindir = $(prefix)/bin
libdir = $(prefix)/lib

BUILDDIR = $(xcodebuild -showBuildSettings | grep CONFIGURATION_BUILD_DIR)

build:
	xcodebuild -scheme muter -configuration Debug > /dev/null 2>&1

build-release:
	xcodebuild -scheme muter -configuration Release > /dev/null 2>&1

release:
	./Scripts/shipIt.sh $(VERSION)

install: build-release
	install -d "$(bindir)" "$(libdir)"
	install "$(BUILDDIR)/Release/muter" "$(bindir)"
	install "$(BUILDDIR)/Release/libSwiftSyntax.dylib" "$(libdir)"
	install_name_tool -change \
	"$(BUILDDIR)/Release/libSwiftSyntax.dylib" \
	"$(libdir)/libSwiftSyntax.dylib" \
	"$(bindir)/muter"

uninstall:
	rm -rf "$(bindir)/muter"
	rm -rf "$(libdir)/libSwiftSyntax.dylib"

clean:
	rm -rf .build

run: build
	$(BUILDDIR)/Bebug/muter

test: build
	xcodebuild -scheme muter -only-testing:muterCoreTests test
	
acceptance-test: build
	./AcceptanceTests/runAcceptanceTests.sh

regression-test: build
	./RegressionTests/runRegressionTests.sh

mutation-test: clean
	muter

.PHONY: build build-tests clean test run install uninstall release
