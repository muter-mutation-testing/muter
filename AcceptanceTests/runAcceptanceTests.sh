#!/bin/sh

echo "📴📴📴📴📴📴📴 Acceptance Testing has started 📴📴📴📴📴📴📴"

muterdir="../../.build/debug"
samplesdir="../../AcceptanceTests/samples"

echo "Cleaning up from prior acceptance test runs..."
rm -rf ./AcceptanceTests/samples/muter_logs
rm -rf ./AcceptanceTests/samples

mkdir -p ./AcceptanceTests/samples
mkdir -p ./AcceptanceTests/samples/muter_logs

echo "Running Muter on an iOS codebase with a test suite..."
cd ./Repositories/ExampleApp

echo " > Creating a configuration file..."
"$muterdir"/muter init
cp ./muter.conf.yml "$samplesdir"/created_iOS_config.yml

echo " > Running in CLI mode..."
"$muterdir"/muter --skip-coverage > "$samplesdir"/muters_output.txt
echo " > Copying logs..."
cp -R ./muter_logs "$samplesdir"/
rm -rf ./muter_logs

echo " > Running with coverage"
"$muterdir"/muter > "$samplesdir"/muters_with_coverage_output.txt
rm -rf ./muter_logs

echo " > Running in Xcode mode..."
"$muterdir"/muter --output-xcode --skip-coverage > "$samplesdir"/muters_xcode_output.txt
rm -rf ./muter_logs # don't pollute the staging area

echo " > Running with --filesToMutate flag"
"$muterdir"/muter --skip-coverage --files-to-mutate "/ExampleApp/Module.swift" > "$samplesdir"/muters_files_to_mutate_output.txt
rm -rf ./muter_logs # don't pollute the staging area

rm muter.conf.yml # cleanup the created configuration file for the next test run
cd ../..

echo "Initializing Muter on an macOS codebase with a test suite..."
cd ./Repositories/ExampleMacOSApp

echo " > Creating a configuration file..."
"$muterdir"/muter init
cp ./muter.conf.yml "$samplesdir"/created_macOS_config.yml

echo " > Cleaning up after test..."
rm muter.conf.yml # cleanup the created configuration file for the next test run
cd ../..

echo "Running Muter on an empty example codebase..."
cd ./Repositories/EmptyExampleApp

echo " > Running in CLI mode..."
"$muterdir"/muter --skip-coverage > "$samplesdir"/muters_empty_state_output.txt
cd ../..

echo "Running Muter on an example test suite that fails..."
cd ./Repositories/ProjectWithFailures

echo " > Running in CLI mode..."
"$muterdir"/muter --skip-coverage > "$samplesdir"/muters_aborted_testing_output.txt
rm -rf ./muter_logs # don't pollute the staging area

cd ../..

echo "Running Muter's help command..."
cd ./Repositories/ExampleApp

echo " > Running help command..."
"$muterdir"/muter help > "$samplesdir"/muters_help_output.txt

echo " > Running init help command..."
"$muterdir"/muter help init > "$samplesdir"/muters_init_help_output.txt

echo " > Running run help command..."
"$muterdir"/muter help run > "$samplesdir"/muters_run_help_output.txt

cd ../..

echo "Running tests..."

export acceptance_tests=true
swift test

exitCode=$?

unset acceptance_tests

exit $exitCode

echo "📳📳📳📳📳📳📳 Acceptance Testing has finished 📳📳📳📳📳📳📳"
