#!/bin/sh

echo "🦕🦕🦕🦕🦕🦕🦕🦕 Regression Testing has started 🦕🦕🦕🦕🦕🦕🦕🦕"

echo "Running Regression Test on BonMot..."
cd ./Repositories/BonMot
../../.build/x86_64-apple-macosx/debug/muter --output-json &> muterReport.json
cp ./muterReport.json ../../RegressionTests/bonmot_regression_test_output.json
cd ../..

echo "Running Regression Test on Parser Combinator..."
cd ./Repositories/FFCParserCombinator
swift package generate-xcodeproj
../../.build/x86_64-apple-macosx/debug/muter --output-json &> muterReport.json
cp ./muterReport.json ../../RegressionTests/parsercombinator_regression_test_output.json
cd ../..

echo "Running Regression Test on Project With Concurrency..."
cd ./Repositories/ProjectWithConcurrency
swift package generate-xcodeproj
../../.build/x86_64-apple-macosx/debug/muter --output-json &> muterReport.json
cp ./muterReport.json ../../RegressionTests/projectwithconcurrency_test_output.json
cd ../..

swift package generate-xcodeproj
xcodebuild -scheme muter -only-testing:muterRegressionTests test

echo "🦖🦖🦖🦖🦖🦖🦖🦖 Regression Testing has finished 🦖🦖🦖🦖🦖🦖🦖🦖"
