#!/bin/bash
set -xe
cd "$(dirname "$0")"/../.cache/downloads

# Create temporary files
whitelist=$(mktemp)
all_items=$(mktemp)
to_delete=$(mktemp)

# Ensure cleanup
trap 'rm -f "$whitelist" "$all_items" "$to_delete"' EXIT

# 1. Add all symlink names and their targets to whitelist, NUL-separated.
find . -maxdepth 1 -type l -printf '%f\0%l\0' > "$whitelist"

# 2. Sort and unique the whitelist
sort -z -u -o "$whitelist" "$whitelist"

# 3. List all items (files, dirs, symlinks) except ., NUL-separated and sorted.
# We use maxdepth 1 to only clean the current directory (flat cache).
find . -mindepth 1 -maxdepth 1 -printf '%f\0' | sort -z > "$all_items"

# 4. Determine items to delete (in all_items but not in whitelist)
comm -z -23 "$all_items" "$whitelist" > "$to_delete"

# 5. Delete them
if [ -s "$to_delete" ]; then
    # The to_delete file is already NUL-separated.
    # Use rm -rf to delete directories if they appear in the list.
    xargs -0 rm -rf -- < "$to_delete"
fi
