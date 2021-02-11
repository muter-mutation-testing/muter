#!/bin/bash

set -o pipefail

llvm_export=$(swift test --enable-code-coverage --verbose | tail -1)
llvm_report="${llvm_export/llvm-cov export/llvm-cov report} --ignore-filename-regex='.build|Tests'"

percentage=$(eval "$llvm_report" | egrep "TOTAL" | awk '{ print $4 }')

myPath=$(dirname "$0")
badge=$(swift "$myPath/coverage_to_color.swift" "$percentage")

envman add --key COVERAGE_BADGE_DATA --value "$badge"