#!/bin/bash

if [ "$1" == "" ]; then
    echo "Provide a version string in order to release a new build"
    exit
else 
    echo "Bumping version number inside of version.swift..."
    echo "let version = \"$1\"" > ./Sources/muterCore/version.swift

    echo "Committing new version..."
    git checkout -b $1
    git add ./Sources/muterCore/version.swift
    git commit -m "Bump version to $1"
    git tag "$1"
    git push origin head
    git push origin head --tags

    echo "Generating SHA256 hash of the new version..."
    curl -L "https://github.com/SeanROlszewski/muter/archive/$1.zip" -o new_muter_version.zip
    SHA=$(shasum -a 256 "./new_muter_version.zip" | cut -d " " -f 1) 
    rm new_muter_version.zip

    echo "Updating Homebrew formula..."
    python ./Scripts/bump_version.py $1 $SHA

    echo "Uninstalling old version..."
    make uninstall
    brew uninstall muter

    cd ./homebrew-formulae/Formula/  

    echo "Testing new Homebrew formula..."
    brew install --build-from-source ./muter.rb
    
    echo "Homebrew formula is ready for pushing! Merge the new version branch in the Muter repository back into master, and make a new commit inside the Homebrew formula repository"
fi
