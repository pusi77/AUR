#!/usr/bin/env python3
"""Print a JSON list of {"pkg", "ver"} for packages nvchecker says are outdated.

Old versions come from each package's .SRCINFO, so no state is kept between runs.
"""
import json
import re
import subprocess
from pathlib import Path

root = Path(__file__).resolve().parent.parent
old = {}
for srcinfo in root.glob("*/.SRCINFO"):
    m = re.search(r"^\s*pkgver = (.+)$", srcinfo.read_text(), re.M)
    old[srcinfo.parent.name] = {"version": m.group(1)}
(root / "old.json").write_text(json.dumps({"version": 2, "data": old}))

# json log on stdout, pretty log on stderr (shows up in the Actions log)
out = subprocess.run(["nvchecker", "-c", root / "nvchecker.toml", "--logger", "both"],
                     stdout=subprocess.PIPE, text=True, check=True).stdout
updates = []
for line in out.splitlines():
    try:
        event = json.loads(line)
    except json.JSONDecodeError:
        continue
    if event.get("event") == "updated" and event["name"] in old:
        updates.append({"pkg": event["name"], "ver": event["version"]})
print(json.dumps(updates))
