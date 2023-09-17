#!/bin/sh

echo "📴📴📴📴📴📴📴 Acceptance Testing has started 📴📴📴📴📴📴📴"

muterdir="../../../.build/debug"
samplesdir="../../samples"

echo "Cleaning up from prior acceptance test runs..."
rm -rf ./AcceptanceTests/samples/muter_logs
rm -rf ./AcceptanceTests/samples
rm -rf ./AcceptanceTests/Repositories

mkdir -p ./AcceptanceTests/samples
mkdir -p ./AcceptanceTests/samples/muter_logs

cp -R ./Repositories ./AcceptanceTests

echo "Running Muter on an iOS codebase with a test suite..."
cd ./AcceptanceTests/Repositories/ExampleApp

echo " > Creating a configuration file..."
"$muterdir"/muter init
#cp ./muter.conf.yml "$samplesdir"/created_iOS_config.yml
#
#echo " > Running in CLI mode..."
#"$muterdir"/muter --skip-coverage --skip-update-check > "$samplesdir"/muters_output.txt
#echo " > Copying logs..."
#cp -R ./muter_logs "$samplesdir"/
#rm -rf ./muter_logs
#
echo " > Running with coverage"
"$muterdir"/muter --skip-update-check > "$samplesdir"/muters_with_coverage_output.txt
rm -rf ./muter_logs

#echo " > Running in Xcode mode..."
#"$muterdir"/muter --format xcode --skip-coverage --skip-update-check > "$samplesdir"/muters_xcode_output.txt
#rm -rf ./muter_logs # don't pollute the staging area

#echo " > Running with --filesToMutate flag"
#"$muterdir"/muter --skip-coverage --skip-update-check --files-to-mutate "/ExampleApp/Module.swift" > "$samplesdir"/muters_files_to_mutate_output.txt
#rm -rf ./muter_logs # don't pollute the staging area
#
#rm muter.conf.yml # cleanup the created configuration file for the next test run
#cd ../..
#
#echo "Initializing Muter on an macOS codebase with a test suite..."
#cd ./Repositories/ExampleMacOSApp
#
#echo " > Creating a configuration file..."
#"$muterdir"/muter init
#cp ./muter.conf.yml "$samplesdir"/created_macOS_config.yml
#
#echo " > Cleaning up after test..."
#rm muter.conf.yml # cleanup the created configuration file for the next test run
#cd ../..
#
#echo "Running Muter on an empty example codebase..."
#cd ./Repositories/EmptyExampleApp
#
#echo " > Running in CLI mode..."
#"$muterdir"/muter --skip-coverage --skip-update-check > "$samplesdir"/muters_empty_state_output.txt
#cd ../..
#
#echo "Running Muter on an example test suite that fails..."
#cd ./Repositories/ProjectWithFailures
#
#echo " > Running in CLI mode..."
#"$muterdir"/muter --skip-coverage --skip-update-check > "$samplesdir"/muters_aborted_testing_output.txt
#rm -rf ./muter_logs # don't pollute the staging area
#
#cd ../..
#
#echo "Running Muter's help command..."
#cd ./Repositories/ExampleApp
#
#echo " > Running help command..."
#"$muterdir"/muter help > "$samplesdir"/muters_help_output.txt
#
#echo " > Running init help command..."
#"$muterdir"/muter help init > "$samplesdir"/muters_init_help_output.txt
#
#echo " > Running run help command..."
#"$muterdir"/muter help run > "$samplesdir"/muters_run_help_output.txt
#
#echo " > Running operators help command..."
#"$muterdir"/muter help operator > "$samplesdir"/muters_operator_help_output.txt
#
#echo " > Running all operators command..."
#"$muterdir"/muter operator all > "$samplesdir"/muters_operator_all_output.txt

cd ../../..

rm -rf ./AcceptanceTests/Repositories

echo "Running tests..."

swift test --filter 'AcceptanceTests'

exitCode=$?

rm -rf ./AcceptanceTests/samples

exit $exitCode

echo "📳📳📳📳📳📳📳 Acceptance Testing has finished 📳📳📳📳📳📳📳"
