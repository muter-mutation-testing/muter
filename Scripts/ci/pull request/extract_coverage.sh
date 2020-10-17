#!/bin/bash

set -o pipefail

TARGETS=$(xcrun xccov view --only-targets --report --json $XCRESULT_PATH)

BADGE=$(swift coverage_to_color.swift "$TARGETS")

envman add --key COVERAGE_BADGE_DATA --value "$BADGE"