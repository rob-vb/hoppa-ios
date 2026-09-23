#!/usr/bin/env python3
"""Check store/listing.md fields against App Store Connect limits."""
import re, sys, pathlib

LIMITS = {"Name": 30, "Subtitle": 30, "Promotional text": 170, "Keywords": 100, "Description": 4000}
text = pathlib.Path(__file__).with_name("listing.md").read_text()
failed = False
for lang in re.split(r"^## ", text, flags=re.M)[1:]:
    title = lang.splitlines()[0]
    for field, limit in LIMITS.items():
        m = re.search(rf"\*\*{field}\*\* \(\d+[^)]*\):\s*(?:```\n(.*?)\n```|`([^`\n]*)`)", lang, re.S)
        if not m:
            continue
        value = m.group(1) if m.group(1) is not None else m.group(2)  # block, else inline
        size = len(value.encode()) if field == "Keywords" else len(value)
        ok = size <= limit and not (field == "Keywords" and " " in value)
        failed |= not ok
        print(f"{'PASS' if ok else 'FAIL'}  {title[:16]:16} {field:17} {size:4}/{limit}")
sys.exit(1 if failed else 0)
