prefix ?= /usr/local
bindir = $(prefix)/bin
libdir = $(prefix)/lib

build:
	swift build -c release --disable-sandbox

install: build
	cp ".build/release/muter" "$(bindir)"
	cp ".build/release/libSwiftSyntax.dylib" "$(libdir)"
	install_name_tool -change \
	".build/x86_64-apple-macosx10.10/release/libSwiftSyntax.dylib" \
	"$(libdir)/libSwiftSyntax.dylib" \
	"$(bindir)/muter"

uninstall:
	rm -rf "$(bindir)/muter"
	rm -rf "$(libdir)/libSwiftSyntax.dylib"

clean:
	rm -rf .build

.PHONY: build install uninstall clean
