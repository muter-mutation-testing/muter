# ${parameter:-word}
#    If parameter is unset or null, the expansion of word is substituted. 
#    Otherwise, the value of parameter is substituted.
configuration="${1:-Debug}"

# pluck out "CONFIGURATION_BUILD_DIR" and then extract just the file path
# -o prints only the matched (non-empty) parts
# -E uses extended regular expression
# -i ignores case distinctions
xcodebuild -configuration "$configuration" -showBuildSettings | grep "CONFIGURATION_BUILD_DIR" | grep -oEi "\/.*"