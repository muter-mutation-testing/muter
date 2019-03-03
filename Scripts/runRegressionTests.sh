#!/bin/sh

echo "🦕🦕🦕🦕🦕🦕🦕🦕 Regression Testing has started 🦕🦕🦕🦕🦕🦕🦕🦕"

echo "Running Regression Test on Bon Mot..."
cd ./Repositories/BonMot
../../.build/x86_64-apple-macosx10.10/debug/muter --output-json
cp ./muterReport.json ../../RegressionTests/bonmot_regression_test_output.json
cd ../..

echo "Running Regression Test on Parser Combinator..."
cd ./Repositories/FFCParserCombinator
swift package generate-xcodeproj
../../.build/x86_64-apple-macosx10.10/debug/muter --output-json
cp ./muterReport.json ../../RegressionTests/parsercombinator_regression_test_output.json
cd ../..

swift package generate-xcodeproj
xcodebuild -scheme muter -only-testing:muterRegressionTests test

echo "🦖🦖🦖🦖🦖🦖🦖🦖 Regression Testing has finished 🦖🦖🦖🦖🦖🦖🦖🦖"
