#!/bin/bash
# Usage: ci/build.sh <pkg>
# Run as root inside archlinux:base-devel. Locally:
#   docker run --rm -v "$PWD:/repo:ro" archlinux:base-devel /repo/ci/build.sh <pkg>
set -euo pipefail
pkg=$1
repo=$(cd "$(dirname "$0")/.." && pwd)

pacman -Syu --noconfirm --needed git namcap pacman-contrib sudo >/dev/null
id builder &>/dev/null || {
  useradd -m builder
  echo 'builder ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/builder
}
if ! command -v paru >/dev/null; then
  su builder -c 'git clone -q --depth 1 https://aur.archlinux.org/paru-bin.git ~/paru && cd ~/paru && makepkg -si --noconfirm' >/dev/null
fi

rm -rf /home/builder/pkg && cp -r "$repo/$pkg" /home/builder/pkg && chown -R builder: /home/builder/pkg
su builder -c "cd ~/pkg && bash -euo pipefail -s" <<'SH'
echo "::group::.SRCINFO up to date"
diff -u .SRCINFO <(makepkg --printsrcinfo)
echo "::endgroup::"

echo "::group::build + install (paru -Ui)"
paru -Ui --noconfirm --skipreview
echo "::endgroup::"

echo "::group::namcap (informational)"
namcap PKGBUILD *.pkg.tar.* || true
echo "::endgroup::"

if [[ -f test.sh ]]; then
  echo "::group::test.sh"
  export pkgname pkgver
  pkgname=$(sed -n 's/^\s*pkgbase = //p' .SRCINFO)
  pkgver=$(sed -n 's/^\s*pkgver = //p' .SRCINFO)
  bash -euxo pipefail test.sh
  echo "::endgroup::"
else
  echo "no test.sh, build + install only"
fi
SH
