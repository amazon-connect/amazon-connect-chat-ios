#!/bin/bash

# Path to the DerivedData directory (modify as needed)
DERIVED_DATA_PATH="${HOME}/Library/Developer/Xcode/DerivedData"

# Find the latest .xcresult file
XCRESULT_PATH=$(find "$DERIVED_DATA_PATH" -type d -name "*.xcresult" -print0 | xargs -0 stat -f "%m %N" | sort -rn | head -n 1 | cut -d' ' -f2-)

if [ -z "$XCRESULT_PATH" ]; then
  echo "No .xcresult file found in $DERIVED_DATA_PATH"
  exit 1
fi

echo "Using .xcresult file: $XCRESULT_PATH"

# Temporary coverage report file
TEMP_COVERAGE_REPORT="temp_coverage.json"

# Output coverage report file
OUTPUT_COVERAGE_REPORT="filtered_coverage.json"

# Folder to exclude (modify as needed)
EXCLUDE_FOLDER="Models"

# Generate the initial coverage report
xcrun xccov view --report --json "$XCRESULT_PATH" > $TEMP_COVERAGE_REPORT

if [ $? -ne 0 ]; then
  echo "Error: Failed to generate coverage report."
  rm $TEMP_COVERAGE_REPORT
  exit 1
fi

# Construct the jq filter for excluding files in a specific folder
exclude_filter='map(select(.path | test("'"$EXCLUDE_FOLDER"'") | not))'

# Filter out the specified files
jq ".targets[].files |= $exclude_filter" $TEMP_COVERAGE_REPORT > $OUTPUT_COVERAGE_REPORT

if [ $? -ne 0 ]; then
  echo "Error: Failed to filter coverage report."
  rm $TEMP_COVERAGE_REPORT
  exit 1
fi

# Clean up temporary files
rm $TEMP_COVERAGE_REPORT

echo "Filtered coverage report generated at $OUTPUT_COVERAGE_REPORT"

