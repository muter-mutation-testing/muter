#!/bin/sh

echo "🦕🦕🦕🦕🦕🦕🦕🦕 Regression Testing has started 🦕🦕🦕🦕🦕🦕🦕🦕"

muterdir="../../.build/debug"
samplesdir="../../RegressionTests/samples"

rm -rf ./RegressionTests/samples
mkdir -p ./RegressionTests/samples

# Muter writes its logs next to each project, in `../<project>_muter_logs`.
rm -rf ./Repositories/*_muter_logs

# Runs Muter on one project and copies its report to the samples.
# The projects are independent: each one has its own `_mutated` copy and `_muter_logs` folder.
# So they run at the same time, and each run writes its output to `RegressionTests/samples/<sample>.log`. A failed run fails the script.
regression_test() {
    project="$1"
    sample="$2"
    shift 2

    (
        start=$(date +%s)
        cd "./Repositories/$project" || exit 1
        # A report from an earlier run must not stand in for this one.
        rm -f muterReport.json
        "$muterdir"/muter --skip-update-check --format json --output muterReport.json "$@" > "$samplesdir/$sample.log" 2>&1
        status=$?
        cp ./muterReport.json "$samplesdir/$sample.json" || status=1
        echo "⏱  $project finished in $(( $(date +%s) - start ))s (exit $status)"
        exit $status
    ) &
    pids="$pids $!"
}

pids=""

start=$(date +%s)

echo "Running Regression Tests on BonMot, Parser Combinator and Project With Concurrency..."
regression_test BonMot bonmot_regression_test_output
regression_test FFCParserCombinator parsercombinator_regression_test_output --skip-coverage
regression_test ProjectWithConcurrency projectwithconcurrency_test_output --skip-coverage
muterStatus=0
for pid in $pids; do
    wait "$pid" || muterStatus=1
done

echo "⏱  Muter runs finished in $(( $(date +%s) - start ))s"

rm -rf ./Repositories/*_muter_logs

swift test --filter 'RegressionTests'

exitCode=$?
if [ $muterStatus -ne 0 ]; then
    echo "❌ A Muter run failed. Its output is in RegressionTests/samples/*.log."
    exitCode=1
fi

echo "🦖🦖🦖🦖🦖🦖🦖🦖 Regression Testing has finished 🦖🦖🦖🦖🦖🦖🦖🦖"

exit $exitCode
