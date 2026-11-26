# AUR

Mirror of the AUR packages I maintain. One directory per package (dir name = pkgbase),
imported with full AUR history. This repo is the source of truth: AUR is written only by CI.

## Flow

1. **check.yml** (daily): `ci/check.py` seeds nvchecker's old versions from each `.SRCINFO`,
   runs `nvchecker.toml`, and for each outdated package bumps `pkgver`, resets `pkgrel`,
   runs `updpkgsums` + regenerates `.SRCINFO` (`ci/bump.sh`), then opens/updates a PR on
   branch `update/<pkg>`.
2. **test.yml** (every PR, weekly for all packages): `ci/build.sh` in `archlinux:base-devel`
   checks `.SRCINFO` is current, builds + installs with `paru -Ui` (AUR deps work),
   runs namcap (informational), then the package's `test.sh`.
3. You review and merge.
4. **publish.yml** (push to master): `ci/publish.sh` copies each changed package dir
   (minus `test.sh`) into its AUR repo as one commit and pushes. Manual re-publish:
   run the workflow with a package name.

## Tests

`<pkg>/test.sh` is optional, runs after install as a normal user with `bash -euxo pipefail`.
`$pkgname` and `$pkgver` are set. Any non-zero exit fails the PR. Example:

```sh
[ "$(rain -v)" = "Rain v$pkgver linux/amd64" ]
```

Run locally: `docker run --rm -v "$PWD:/repo:ro" archlinux:base-devel /repo/ci/build.sh rain`

## Adding a package

Import with history: `git subtree add --prefix=<pkg> https://aur.archlinux.org/<pkg>.git master`
(or just create the dir for a new package), add a `test.sh` and an `nvchecker.toml` entry
keyed by the dir name whose version matches `pkgver` exactly (use `prefix = "v"` etc.).

## Setup

Repository secrets:

- `AUR_SSH_KEY`: private key registered on your AUR account (use a dedicated one).
- `PR_TOKEN`: fine-grained PAT for this repo with *Contents* and *Pull requests* read/write.
  Needed because PRs opened with `GITHUB_TOKEN` don't trigger `test.yml`.

Caveats:

- Anything pushed to AUR outside this repo (co-maintainer, web edit) gets overwritten on the next publish.
- GitHub disables cron workflows after 60 days without repo activity. If updates stop, re-enable `check.yml` in the Actions tab.
