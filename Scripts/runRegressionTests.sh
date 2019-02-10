#!/bin/sh
echo "🦕🦕🦕🦕🦕🦕🦕🦕 Regression Testing has started 🦕🦕🦕🦕🦕🦕🦕🦕"

echo "Running Regression Test on Bon Mot..."
cd ./Repositories/BonMot
../../.build/x86_64-apple-macosx10.10/debug/muter --output-json
cp ./muterReport.json ../../Tests/bonmot_regression_test_output.json
cd ../..
make test

echo "🦖🦖🦖🦖🦖🦖🦖🦖 Regression Testing has finished 🦖🦖🦖🦖🦖🦖🦖🦖"
