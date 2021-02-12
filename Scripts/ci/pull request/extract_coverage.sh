#!/bin/bash

set -o pipefail

# --verbose will output llvm-cov command
llvm_export=$(swift test --enable-code-coverage --verbose | tail -1)

# bail out if error
if [ $? -ne 0 ]; then
    exit 1
fi

# export coverage but ignore .build and any test targets
llvm_report="${llvm_export/llvm-cov export/llvm-cov report} --ignore-filename-regex='.build|Tests'"

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
