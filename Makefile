prefix ?= /usr/local
bindir = $(prefix)/bin
libdir = $(prefix)/lib

repodir = $(shell pwd)
builddir = $(repodir)/.build
flags=-Xlinker -weak-l_InternalSwiftSyntaxParser -Xswiftc -suppress-warnings

build: 
	swift build -c debug $(flags)

build-release: 
	swift build -c release --product muter --disable-sandbox $(flags)

project:
	swift package generate-xcodeproj

release: 
	./Scripts/shipIt.sh $(version)

install: build-release
	install -d "$(bindir)" "$(libdir)"
	install "$(builddir)/release/muter" "$(bindir)"

uninstall:
	rm -rf "$(bindir)/muter"

clean:
	rm -rf .build

run: build
	$(builddir)/debug/muter

test: 
	swift package generate-xcodeproj
	@./Scripts/test_only.sh "muterTests"
	
acceptance-test: build
	./AcceptanceTests/runAcceptanceTests.sh

regression-test: build
	./RegressionTests/runRegressionTests.sh

mutation-test: clean
	muter

.PHONY: build clean test run install uninstall release