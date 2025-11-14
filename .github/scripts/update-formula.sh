#!/bin/bash
# Updates Homebrew formula with new version and SHA256
# Preserves gem resource blocks unchanged
#
# Usage: update-formula.sh <formula_file> <version> <sha256> <repo>

set -euo pipefail

FORMULA_FILE="$1"
LATEST_VERSION="$2"
NEW_SHA256="$3"
REPO="$4"

if [ $# -ne 4 ]; then
  echo "Usage: $0 <formula_file> <version> <sha256> <repo>"
  exit 1
fi

if [ ! -f "$FORMULA_FILE" ]; then
  echo "Error: Formula file not found: $FORMULA_FILE"
  exit 1
fi

echo "Updating formula: $FORMULA_FILE"
echo "Version: v$LATEST_VERSION"
echo "SHA256: $NEW_SHA256"
echo "Repo: $REPO"

# Create a temporary file for processing
TMP_FILE="${FORMULA_FILE}.tmp"
cp "$FORMULA_FILE" "$TMP_FILE"

# Use awk to update only the FIRST url and sha256 (before any 'resource' blocks)
awk -v version="$LATEST_VERSION" -v sha="$NEW_SHA256" -v repo="$REPO" '
BEGIN { url_updated = 0; sha_updated = 0 }

# Stop processing url/sha after we hit a resource block
/^[[:space:]]*resource / { in_resource = 1 }

# Update URL (only first occurrence, before resource blocks)
!in_resource && /url.*github\.com.*archive\/refs\/tags\/v/ && url_updated == 0 {
  sub(/archive\/refs\/tags\/v[0-9]+\.[0-9]+\.[0-9]+\.tar\.gz/, "archive/refs/tags/v" version ".tar.gz")
  url_updated = 1
}

# Update SHA256 (only first occurrence, before resource blocks)
!in_resource && /sha256/ && sha_updated == 0 {
  sub(/sha256 '\''[^'\'']+'\''/, "sha256 '\''" sha "'\''")
  sha_updated = 1
}

{ print }

END {
  if (url_updated == 0) {
    print "Warning: URL was not updated" > "/dev/stderr"
    exit 1
  }
  if (sha_updated == 0) {
    print "Warning: SHA256 was not updated" > "/dev/stderr"
    exit 1
  }
}
' "$TMP_FILE" > "${FORMULA_FILE}.new"

# Replace original with updated version
mv "${FORMULA_FILE}.new" "$FORMULA_FILE"
rm -f "$TMP_FILE"

echo "✅ Successfully updated $FORMULA_FILE"
