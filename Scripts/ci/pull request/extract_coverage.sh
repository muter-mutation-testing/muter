#!/bin/bash

set -o pipefail

swift test --filter 'muterTests' --enable-code-coverage

# bail out if error
if [ $? -ne 0 ]; then
    exit 1
fi

toolchain="$(xcode-select -p)/Toolchains/XcodeDefault.xctoolchain/usr/bin/llvm-cov"
xctest=".build/debug/muterPackageTests.xctest/Contents/MacOS/muterPackageTests"

# export coverage but ignore .build and any test targets
llvm_report="$toolchain report $xctest -instr-profile=.build/debug/codecov/default.profdata --ignore-filename-regex='.build|Tests'"

#Filename   Regions    Missed Regions     Cover   Functions  Missed Functions  Executed       Lines      Missed Lines     Cover
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#TOTAL           XX                 X    XX.XX%          XX                 X    XX.XX%         XXX                 X    XX.XX%
#
# We want line cover, which is what Xcode also uses
percentage=$(eval "$llvm_report" | tail -1 |  awk '{ print $10 }')

myPath=$(dirname "$0")
badge=$(swift "$myPath/coverage_to_color.swift" "$percentage") # this will create a valid json that shields.io can process

envman add --key COVERAGE_BADGE_DATA --value "$badge"
