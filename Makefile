prefix ?= /usr/local
bindir = $(prefix)/bin
libdir = $(prefix)/lib

REPODIR = $(shell pwd)
BUILDDIR = $(REPODIR)/.build

build:
	swift build -c release --disable-sandbox

install: build
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

.PHONY: build install uninstall clean
