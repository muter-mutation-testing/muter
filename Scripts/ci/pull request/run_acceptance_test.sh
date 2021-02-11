#!/bin/bash

set -o pipefail

source ./Scripts/test_utils.sh

function passed() {
  XCRESULT_PATH=( ./.derivedData/Logs/Test/*.xcresult )
  XCRESULT_PATH="${XCRESULT_PATH[0]}"
  
  envman add --key XCRESULT_PATH --value "$XCRESULT_PATH"

  exit 0;
}

builddir=$(xcodebuild -showBuildSettings | grep "TOOLCHAIN_DIR" | grep -oEi "\/.*" | tail -1)

xcodebuild -scheme muter \
           -enableCodeCoverage YES \
           -derivedDataPath ./.derivedData \
           -only-testing:muterAcceptanceTests \
           test \
           LD_RUNPATH_SEARCH_PATHS="$builddir/usr/lib/swift/macosx" 2>&1 | parseXcodebuildOutput | xcpretty && passed