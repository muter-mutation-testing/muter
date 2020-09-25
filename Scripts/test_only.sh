# pluck out "CONFIGURATION_BUILD_DIR" and then extract just the file path
# -o prints only the matched (non-empty) parts
# -E uses extended regular expression
# -i ignores case distinctions
builddir=$(xcodebuild -showBuildSettings | grep "TOOLCHAIN_DIR" | grep -oEi "\/.*" | tail -1)

xcodebuild -scheme muter -only-testing:$1 test LD_RUNPATH_SEARCH_PATHS="$builddir/usr/lib/swift/macosx"