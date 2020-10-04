# pluck out "CONFIGURATION_BUILD_DIR" and then extract just the file path
# -o prints only the matched (non-empty) parts
# -E uses extended regular expression
# -i ignores case distinctions
builddir=$(xcodebuild -showBuildSettings | grep "TOOLCHAIN_DIR" | grep -oEi "\/.*" | tail -1)

function parseXcodebuildOutput() {
	while read output; do
		printf "%s\n" "$output"
       	
       	if echo "$output" | grep --quiet "^.*\*\* TEST FAILED \*\*.*$"; then
 			exit 1
 		fi

 		if echo "$output" | grep --quiet "^.*\*\* TEST SUCCEEDED \*\*.*$"; then
 			exit 0
 		fi
  	done
}

xcodebuild -scheme muter -only-testing:$1 test LD_RUNPATH_SEARCH_PATHS="$builddir/usr/lib/swift/macosx" 2>&1 | parseXcodebuildOutput
