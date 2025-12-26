# Pull Request Fixes

This document summarizes the issues found in pull requests #8, #9, and #12, and provides the fixes needed to allow them to merge.

## PR #9: FFmpeg-Builds Debloating (from aandrew-me/FFmpeg-Builds-Custom)

### Issues Found
- Missing trailing newline at end of README.md

### Fixes Applied
See branch: `fix-pr-9`

**README.md:**
- Added missing trailing newline at end of file

### How to Apply
The contributor (aandrew-me) needs to add a trailing newline to README.md in their fork.

---

## PR #12: SVT-AV1-HDR Support (from QuickFatHedgehog/FFmpeg-Builds-SVT-AV1-HDR)

### Issues Found
1. **Critical Bug:** In FFmpeg patches (7.1, 8.0, master), when `svt_enc->crf` exceeds `MAX_QP_VALUE` (63), the `extended_crf_qindex_offset` calculation produces incorrect values outside the expected 0-3 range.

### Fixes Applied
See branch: `fix-pr-12`

**patches/ffmpeg/7.1.patch, patches/ffmpeg/8.0.patch, patches/ffmpeg/master.patch:**

Changed from:
```c
param->qp = FFMIN(MAX_QP_VALUE, (uint32_t)svt_enc->crf);
param->rate_control_mode = 0;
uint32_t extended_q_index = (uint32_t)(svt_enc->crf * 4);
param->extended_crf_qindex_offset = extended_q_index - param->qp * 4;
```

To:
```c
// Cap CRF at MAX_QP_VALUE + 0.75 to ensure extended offset stays in valid range (0-3)
float crf_capped = FFMIN(svt_enc->crf, MAX_QP_VALUE + 0.75f);
param->qp = (uint32_t)crf_capped;
param->rate_control_mode = 0;
// Calculate fractional offset for quarter-step CRF increments
param->extended_crf_qindex_offset = (uint32_t)((crf_capped - param->qp) * 4);
```

### How to Apply
The contributor (QuickFatHedgehog) needs to update all three patch files with the corrected CRF calculation logic.

---

## PR #8: SVT-AV1-Essential (from nekotrix/FFmpeg-Builds-SVT-AV1-Essential)

### Issues Found
1. **Non-functional git tag parsing:** The `new_commit` variable retrieves tag names instead of commit hashes
2. **Fragile shell variable parsing:** Simple string splitting on `=` incorrectly parses shell conditionals like `if [ "$a" = "$b" ]`
3. **Unused imports:** sys, pathlib.Path, shutil

### Fixes Applied
See branch: `fix-pr-8`

**util/update_scripts.py:**

1. Removed unused imports:
```python
# Removed: sys, pathlib.Path, shutil
import os
import subprocess
import re
import glob
import tempfile
import concurrent.futures
```

2. Fixed variable parsing to use regex:
```python
# Old: fragile string split
for line in content.splitlines():
    if '=' in line:
        key, value = line.split('=', 1)
        script_vars[key.strip()] = value.strip().strip('"\'')

# New: proper regex matching
for line in content.splitlines():
    match = re.match(r'^\s*([A-Z_][A-Z0-9_]*)\s*=\s*(.*)$', line)
    if match:
        key, value = match.groups()
        script_vars[key] = value.strip().strip('"\'')
```

3. Fixed tag commit extraction:
```python
# Old: extracts tag name
new_commit = output.splitlines()[-1].split('/')[2].strip()

# New: extracts commit hash
new_commit = output.splitlines()[-1].split()[0]

# Also added missing update logic
if new_commit != current_commit:
    print(f"Updating {script_path}")
    content = re.sub(
        f'{commit_var}=.*',
        f'{commit_var}="{new_commit}"',
        content,
        flags=re.MULTILINE
    )
```

### How to Apply
The contributor (nekotrix) needs to update util/update_scripts.py with these fixes.

---

## Summary

All three PRs have code quality issues identified by automated review that need to be addressed before merging:

- **PR #9:** Simple formatting fix (newline)
- **PR #12:** Critical bug fix in CRF calculation
- **PR #8:** Multiple code quality improvements in Python script

Reference branches with fixes:
- `fix-pr-9`: Contains fixed README.md
- `fix-pr-12`: Contains fixed FFmpeg patches
- `fix-pr-8`: Contains fixed update_scripts.py

The contributors will need to apply these fixes to their respective forks before the PRs can be safely merged.
