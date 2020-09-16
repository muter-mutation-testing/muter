#!/bin/sh

echo "🦕🦕🦕🦕🦕🦕🦕🦕 Regression Testing has started 🦕🦕🦕🦕🦕🦕🦕🦕"

BUILDDIR=$(xcodebuild -configuration Debug -showBuildSettings | grep "CONFIGURATION_BUILD_DIR" | grep -oEi "\/.*")

echo "Running Regression Test on BonMot..."
cd ./Repositories/BonMot
"$BUILDDIR"/muter --output-json > muterReport.json

cp ./muterReport.json ../../RegressionTests/bonmot_regression_test_output.json
cd ../..

echo "Running Regression Test on Parser Combinator..."
cd ./Repositories/FFCParserCombinator
"$BUILDDIR"/muter --output-json > muterReport.json
cp ./muterReport.json ../../RegressionTests/parsercombinator_regression_test_output.json
cd ../..

echo "Running Regression Test on Project With Concurrency..."
cd ./Repositories/ProjectWithConcurrency
"$BUILDDIR"/muter --output-json > muterReport.json
cp ./muterReport.json ../../RegressionTests/projectwithconcurrency_test_output.json
cd ../..

xcodebuild -scheme muter -only-testing:RegressionTests test

echo "🦖🦖🦖🦖🦖🦖🦖🦖 Regression Testing has finished 🦖🦖🦖🦖🦖🦖🦖🦖"
