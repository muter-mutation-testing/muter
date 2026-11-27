#!/bin/sh

# Runs the regression and the acceptance tests at the same time, and prints the output of each one
# when both are done. They run Muter on different copies of the projects, so they do not share files.
# Exits with 1 when one of them fails.

logdir="./.build/test-logs"
mkdir -p "$logdir"

start=$(date +%s)

./RegressionTests/runRegressionTests.sh > "$logdir/regression.log" 2>&1 &
regression=$!

./AcceptanceTests/runAcceptanceTests.sh > "$logdir/acceptance.log" 2>&1 &
acceptance=$!

wait $regression
regressionStatus=$?
regressionTime=$(( $(date +%s) - start ))

wait $acceptance
acceptanceStatus=$?
acceptanceTime=$(( $(date +%s) - start ))

cat "$logdir/regression.log"
cat "$logdir/acceptance.log"

echo "⏱  Regression tests: exit $regressionStatus after ${regressionTime}s"
echo "⏱  Acceptance tests: exit $acceptanceStatus after ${acceptanceTime}s"
echo "⏱  Both finished in $(( $(date +%s) - start ))s"

[ $regressionStatus -eq 0 ] && [ $acceptanceStatus -eq 0 ]
