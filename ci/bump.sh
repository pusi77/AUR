#!/bin/bash
# Usage: ci/bump.sh <pkg> <version>   (run on Arch as a non-root user)
set -euo pipefail
cd "$(dirname "$0")/../$1"
[[ $2 =~ ^[A-Za-z0-9._+]+$ ]] || { echo "refusing weird pkgver: $2" >&2; exit 1; }
sed -i -e "s/^pkgver=.*/pkgver=$2/" -e "s/^pkgrel=.*/pkgrel=1/" PKGBUILD
updpkgsums
makepkg --printsrcinfo > .SRCINFO
git diff --stat .
