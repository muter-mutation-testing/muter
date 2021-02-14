#!/bin/sh

echo "🦕🦕🦕🦕🦕🦕🦕🦕 Regression Testing has started 🦕🦕🦕🦕🦕🦕🦕🦕"

muterdir="../../.build/debug"
samplesdir="../../RegressionTests/samples"

rm -rf ./RegressionTests/samples
mkdir -p ./RegressionTests/samples

echo "Running Regression Test on BonMot..."
cd ./Repositories/BonMot
"$muterdir"/muter --output-json > muterReport.json

cp ./muterReport.json "$samplesdir"/bonmot_regression_test_output.json
cd ../..

echo "Running Regression Test on Parser Combinator..."
cd ./Repositories/FFCParserCombinator
"$muterdir"/muter --output-json > muterReport.json
cp ./muterReport.json "$samplesdir"/parsercombinator_regression_test_output.json
cd ../..

echo "Running Regression Test on Project With Concurrency..."
cd ./Repositories/ProjectWithConcurrency
swift package generate-xcodeproj
"$muterdir"/muter --output-json > muterReport.json
cp ./muterReport.json "$samplesdir"/projectwithconcurrency_test_output.json
cd ../..

export regression_tests=true
swift test

exitCode=$?

unset regression_tests

exit $exitCode

echo "🦖🦖🦖🦖🦖🦖🦖🦖 Regression Testing has finished 🦖🦖🦖🦖🦖🦖🦖🦖"
