#!/bin/bash

set -o pipefail

make acceptance-test && exit ${PIPESTATUS[0]}
