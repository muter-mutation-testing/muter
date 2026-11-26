#!/bin/bash

if [ "$1" == "" ]; then
    echo "Provide a version string in order to release a new build"
    exit
else 
    echo "Bumping version number inside of version.swift..."
    echo "public let version = \"$1\"" > ./Sources/muterCore/version.swift

    echo "Committing new version..."
    git checkout -b $1
    git add ./Sources/muterCore/version.swift
    git commit -m "Bump version to $1"
    git tag "$1"
    git push origin head
    # Push only the new release tag, not every local tag.
    git push origin "refs/tags/$1"

    echo "Building the release binary..."
    ./Scripts/build_release_binary.sh $1

    echo "Creating a draft GitHub release with the binary..."
    gh release create "$1" --draft --verify-tag --title "$1" --notes "" \
        ".build/release-artifacts/muter-$1-macos-universal.tar.gz" \
        ".build/release-artifacts/muter-$1-macos-universal.tar.gz.sha256"

    echo "Generating SHA256 hash of the new version..."
    curl -L "https://github.com/muter-mutation-testing/muter/archive/refs/tags/$1.zip" -o new_muter_version.zip
    SHA=$(shasum -a 256 "./new_muter_version.zip" | cut -d " " -f 1) 
    rm new_muter_version.zip

    echo "Updating Homebrew formula..."
    python3 ./Scripts/bump_version.py $1 $SHA

    echo "Uninstalling old version..."
    make uninstall
    brew uninstall muter-mutation-testing/formulae/muter

    cd ./homebrew-formulae/Formula/  

    echo "Testing new Homebrew formula..."
    brew install --build-from-source ./muter.rb
    
    echo "Homebrew formula is ready for pushing! Merge the new version branch in the Muter repository back into master, and make a new commit inside the Homebrew formula repository"
    echo "Then write the release notes in the draft GitHub release $1, and publish it."
fi
