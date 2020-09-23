# pluck out "CONFIGURATION_BUILD_DIR" and then extract just the file path
# -o prints only the matched (non-empty) parts
# -E uses extended regular expression
# -i ignores case distinctions
xcodebuild -configuration Release -showBuildSettings | grep "CONFIGURATION_BUILD_DIR" | grep -oEi "\/.*"