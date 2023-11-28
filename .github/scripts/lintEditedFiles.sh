#!/bin/bash

# Install SwiftLint
brew install swiftlint

# Get the list of modified or added Swift files in the commit
modified_files=$(git diff --name-only --diff-filter=AM ${{ github.event.before }} ${{ github.sha }} | grep '\.swift$')
# modified_files=$(curl -sSL "https://api.github.com/repos/${{ github.repository }}/pulls/${{ github.event.number }}/files" | jq -r '.[] | select(.filename | endswith(".swift")) | .filename')

# Check if there are any Swift files to lint
if [ -z "$modified_files" ]; then
  echo "No Swift files to lint."
  exit 0
fi

# Lint the modified Swift files
swiftlint lint --strict --config .swiftlint.yml --path ${modified_files}

# Capture the exit status
lint_exit_status=$?

# Exit with the lint exit status
exit $lint_exit_status