#!/bin/sh
echo "📴📴📴📴📴📴📴 Acceptance Testing has started 📴📴📴📴📴📴📴"

echo "Setting up environment for testing..."

echo "Running Muter on a codebase with a test suite..."
cd ./ExampleApp
../.build/x86_64-apple-macosx10.10/debug/muter > ../Tests/muters_output.txt 

cd ..

echo "Running Muter on an empty example codebase..."
cd ./EmptyExampleApp
../.build/x86_64-apple-macosx10.10/debug/muter > ../Tests/muters_empty_state_output.txt

cd ..

echo "Running Muter on an example test suite that fails..."
cd ./ProjectWithFailures
../.build/x86_64-apple-macosx10.10/debug/muter > ../Tests/muters_aborted_testing_output.txt
cd ..

echo "Running tests..."
make test

echo "📳📳📳📳📳📳📳 Acceptance Testing has finished 📳📳📳📳📳📳📳"
