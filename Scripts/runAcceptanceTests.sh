#!/bin/sh
echo "📴📴📴📴📴📴📴 Acceptance Testing has started 📴📴📴📴📴📴📴"

echo "Setting up environment for testing..."
rm ./Tests/acceptanceTests/muters_output.txt # Clear out the results of the last run of Muter
touch ./Tests/acceptanceTests/muters_output.txt 
git checkout -- ExampleApp/ExampleApp/* # Ensures there are no leftover or accidental changes from a prior run of Muter
cd ./ExampleApp

echo "Running Muter..."
../.build/x86_64-apple-macosx10.10/debug/muter >> ../Tests/acceptanceTests/muters_output.txt 

echo "Running tests..."
cd ../
make test

echo "📳📳📳📳📳📳📳 Acceptance Testing has finished 📳📳📳📳📳📳📳"
