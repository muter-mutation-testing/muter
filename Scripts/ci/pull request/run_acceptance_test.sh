#!/bin/bash

set -o pipefail

function passed() {
    envman add --key BADGE_COLOR --value "success"
    envman add --key BADGE_MESSAGE --value "passing"
    exit 0
}

function failed() {
    envman add --key BADGE_COLOR --value "red"
    envman add --key BADGE_MESSAGE --value "failed"
    exit 1
}

make acceptance-test && passed || failed
