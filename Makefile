prefix ?= /usr/local
bindir = $(prefix)/bin
libdir = $(prefix)/lib

REPODIR = $(shell pwd)
BUILDDIR = $(REPODIR)/.build

build: 
	swift build

build-release:
	swift build -c release --disable-sandbox

build-tests: 
	swift build --target muterTests 

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

make run: build
	$(BUILDDIR)/debug/muter

test: 
	@swift test --filter muterTests.* # Also builds app and test code
	
acceptance-test: clean build
	./Scripts/runAcceptanceTests.sh

.PHONY: build install uninstall clean test build-tests
