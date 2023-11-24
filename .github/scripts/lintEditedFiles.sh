#!/bin/sh

set -o pipefail
git fetch origin main
echo "Fetched"

# Run SwiftLint
START_DATE=$(date +"%s")

# Run SwiftLint for given filename
run_swiftlint() {
    local filename="${1}"
    if [[ "${filename##*.}" == "swift" ]]; then
        swiftlint -- "${filename}"
    fi
}

# Run for both staged and unstaged files
git diff --name-only | while read filename; do run_swiftlint "${filename}"; done
git diff --cached --name-only | while read filename; do run_swiftlint "${filename}"; done


END_DATE=$(date +"%s")

DIFF=$(($END_DATE - $START_DATE))
echo "SwiftLint took $(($DIFF / 60)) minutes and $(($DIFF % 60)) seconds to complete."