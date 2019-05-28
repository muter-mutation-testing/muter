#!/bin/sh
echo "📴📴📴📴📴📴📴 Acceptance Testing has started 📴📴📴📴📴📴📴"

echo "Running Muter on an iOS codebase with a test suite..."
cd ./Repositories/ExampleApp

echo " > Creating a configuration file..."
../../.build/x86_64-apple-macosx/debug/muter init
cp ./muter.conf.json ../../AcceptanceTests/created_iOS_config.json

echo " > Running in CLI mode..."
../../.build/x86_64-apple-macosx/debug/muter > ../../AcceptanceTests/muters_output.txt
echo " > Running in Xcode mode..."
../../.build/x86_64-apple-macosx/debug/muter --output-xcode > ../../AcceptanceTests/muters_xcode_output.txt


rm muter.conf.json # cleanup the created configuration file for the next test run
cd ../..

echo "Initializing Muter on an macOS codebase with a test suite..."
cd ./Repositories/ExampleMacOSApp

echo " > Creating a configuration file..."
../../.build/x86_64-apple-macosx/debug/muter init
cp ./muter.conf.json ../../AcceptanceTests/created_macOS_config.json

echo " > Cleaning up after test..."
rm muter.conf.json # cleanup the created configuration file for the next test run
cd ../..

echo "Running Muter on an empty example codebase..."
cd ./Repositories/EmptyExampleApp

echo " > Running in CLI mode..."
../../.build/x86_64-apple-macosx/debug/muter > ../../AcceptanceTests/muters_empty_state_output.txt
cd ../..

echo "Running Muter on an example test suite that fails..."
cd ./Repositories/ProjectWithFailures

echo " > Running in CLI mode..."
../../.build/x86_64-apple-macosx/debug/muter > ../../AcceptanceTests/muters_aborted_testing_output.txt
cd ../..

echo "Running Muter's help command..."
cd ./Repositories/ExampleApp

echo " > Running command..."
../../.build/x86_64-apple-macosx/debug/muter help > ../../AcceptanceTests/muters_help_output.txt
cd ../..

echo "Running tests..."
swift package generate-xcodeproj
xcodebuild -scheme muter -only-testing:muterAcceptanceTests test

echo "📳📳📳📳📳📳📳 Acceptance Testing has finished 📳📳📳📳📳📳📳"
