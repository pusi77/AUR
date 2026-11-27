#!/bin/bash
# Usage: ci/publish.sh <pkg>   Mirror <pkg>/ (minus test.sh) to its AUR repo as one commit.
# Needs ssh access to aur@aur.archlinux.org.
set -euo pipefail
pkg=$1
repo=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)

git clone -q "ssh://aur@aur.archlinux.org/$pkg.git" "$work"
git -C "$work" rm -rqf --ignore-unmatch .
git -C "$repo" archive HEAD "$pkg" | tar -x -C "$work" --strip-components=1
rm -f "$work/test.sh"

cd "$work"
git add -A
if git diff --cached --quiet; then
  echo "$pkg: AUR already up to date"
  exit 0
fi
git commit -qm "$(git -C "$repo" log -1 --no-merges --format=%B -- "$pkg")"
git push origin HEAD:master
