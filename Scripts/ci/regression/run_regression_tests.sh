#!/bin/bash

function passed() {
	envman add --key BADGE_COLOR --value "success"
	envman add --key BADGE_MESSAGE --value "passing"
}

function failed() {
	envman add --key BADGE_COLOR --value "red"
	envman add --key BADGE_MESSAGE --value "failed"
}

make regression-test && passed || failed
