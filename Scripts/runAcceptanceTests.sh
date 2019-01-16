#!/bin/sh
echo "📴📴📴📴📴📴📴 Acceptance Testing has started 📴📴📴📴📴📴📴"

echo "Setting up environment for testing..."
rm ./Tests/muters_output.txt # Clear out the results of the last run of Muter
rm ./Tests/muters_empty_state_output.txt # Clear out the results of the last run of Muter

touch ./Tests/muters_output.txt 
touch ./Tests/muters_empty_state_output.txt
git checkout -- ExampleApp/ExampleApp/* # Ensures there are no leftover or accidental changes from a prior run of Muter
git checkout -- EmptyExampleApp/* # Ensures there are no leftover or accidental changes from a prior run of Muter

echo "Running Muter on a codebase with a test suite..."
cd ./ExampleApp
../.build/x86_64-apple-macosx10.10/debug/muter >> ../Tests/muters_output.txt 

cd ..

echo "Running Muter on an empty example codebase..."
cd ./EmptyExampleApp
../.build/x86_64-apple-macosx10.10/debug/muter >> ../Tests/muters_empty_state_output.txt

echo "Running tests..."
cd ../
make test

echo "📳📳📳📳📳📳📳 Acceptance Testing has finished 📳📳📳📳📳📳📳"
