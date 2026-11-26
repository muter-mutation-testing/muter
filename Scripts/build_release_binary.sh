#!/bin/bash
# Builds a universal macOS binary (arm64 and x86_64) of Muter and packages it
# for a GitHub release, so tools such as mise can install Muter without
# building it.
#
# Usage: Scripts/build_release_binary.sh <version>
# Output: .build/release-artifacts/muter-<version>-macos-universal.tar.gz
#         and its .sha256 file.

set -euo pipefail

if [ "${1:-}" == "" ]; then
    echo "Usage: $0 <version>"
    exit 1
fi

version="$1"
out=".build/release-artifacts"
archive="muter-$version-macos-universal.tar.gz"
build_flags=(-c release --product muter --arch arm64 --arch x86_64)

swift build "${build_flags[@]}"
binary="$(swift build "${build_flags[@]}" --show-bin-path)/muter"

built_version="$("$binary" --version)"
if [ "$built_version" != "$version" ]; then
    echo "The binary reports version $built_version, but the release is $version."
    exit 1
fi

rm -rf "$out"
mkdir -p "$out/package"
cp "$binary" "$out/package/muter"
cp LICENSE "$out/package/LICENSE"
(cd "$out/package" && COPYFILE_DISABLE=1 tar -czf "../$archive" muter LICENSE)
(cd "$out" && shasum -a 256 "$archive" > "$archive.sha256")
rm -rf "$out/package"

echo "$out/$archive"
