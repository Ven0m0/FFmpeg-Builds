#!/bin/bash
set -xe
cd "$(dirname "$0")"/../.cache/downloads

# Create temporary files
whitelist=$(mktemp)
all_items=$(mktemp)
to_delete=$(mktemp)

# Ensure cleanup
trap 'rm -f "$whitelist" "$all_items" "$to_delete"' EXIT

# 1. Add all symlink names to whitelist
find . -maxdepth 1 -type l -printf "%f\n" > "$whitelist"

# 2. Add all symlink targets to whitelist
# Use %l to get the link target efficiently.
find . -maxdepth 1 -type l -printf "%l\n" >> "$whitelist"

# 3. Sort and unique the whitelist
sort -u -o "$whitelist" "$whitelist"

# 4. List all items (files, dirs, symlinks) except . and sort
# We use maxdepth 1 to only clean the current directory (flat cache).
find . -mindepth 1 -maxdepth 1 -printf "%f\n" | sort > "$all_items"

# 5. Determine items to delete (in all_items but not in whitelist)
comm -23 "$all_items" "$whitelist" > "$to_delete"

# 6. Delete them
if [ -s "$to_delete" ]; then
    # Convert newlines to nulls for xargs -0 to safely handle spaces.
    # Use rm -rf to delete directories if they appear in the list.
    tr '\n' '\0' < "$to_delete" | xargs -0 rm -rf --
fi
