#!/bin/sh
echo "📴📴📴📴📴📴📴 Acceptance Testing has started 📴📴📴📴📴📴📴"

echo "Setting up environment for testing..."
echo "" > ./Tests/muterTests/muters_output.txt # Clear out the results of the last run of Muter
git checkout -- ExampleApp/ExampleApp/* # Ensures there are no leftover or accidental changes from a prior run of Muter
cd ./ExampleApp
rm -rf muter_tmp # Remove Muter's working directory

echo "Running Muter..."
../.build/x86_64-apple-macosx10.10/debug/muter >> ../Tests/muterTests/muters_output.txt 

echo "Running tests..."
swift test

echo "📳📳📳📳📳📳📳 Acceptance Testing has finished 📳📳📳📳📳📳📳"
