#!/bin/sh

set -o pipefail
git fetch origin main
echo "Fetched"

# Run SwiftLint
START_DATE=$(date +"%s")

swiftlint

END_DATE=$(date +"%s")

DIFF=$(($END_DATE - $START_DATE))
echo "SwiftLint took $(($DIFF / 60)) minutes and $(($DIFF % 60)) seconds to complete."