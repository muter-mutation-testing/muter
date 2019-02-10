prefix ?= /usr/local
bindir = $(prefix)/bin
libdir = $(prefix)/lib

REPODIR = $(shell pwd)
BUILDDIR = $(REPODIR)/.build

build: 
	swift build -Xswiftc -suppress-warnings

build-release: 
	swift build -c release --product muter --disable-sandbox -Xswiftc -suppress-warnings

build-tests: 
	swift build --target muterTests -Xswiftc -suppress-warnings

install: build-release
	install -d "$(bindir)" "$(libdir)"
	install "$(BUILDDIR)/release/muter" "$(bindir)"
	install "$(BUILDDIR)/release/libSwiftSyntax.dylib" "$(libdir)"
	install_name_tool -change \
	"$(BUILDDIR)/x86_64-apple-macosx10.10/release/libSwiftSyntax.dylib" \
	"$(libdir)/libSwiftSyntax.dylib" \
	"$(bindir)/muter"

uninstall:
	rm -rf "$(bindir)/muter"
	rm -rf "$(libdir)/libSwiftSyntax.dylib"

clean:
	rm -rf .build

run: build
	$(BUILDDIR)/debug/muter

test: 
	@swift test -Xswiftc -suppress-warnings
	
acceptance-test: build
	./Scripts/runAcceptanceTests.sh

regression-test: build
	./Scripts/runRegressionTests.sh

mutation-test: clean
	muter

.PHONY: build build-tests clean test run install uninstall  
