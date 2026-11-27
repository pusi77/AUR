# AUR

GitHub mirror of the [AUR packages I maintain](https://aur.archlinux.org/packages?K=pusi77&SeB=m).
This repo is the source of truth: packages are updated through pull requests here, and AUR
is written only by CI, as `pusi77-robot`.

| Package | Update source |
|---|---|
| awsm-bin | GitHub releases |
| ciphey | GitHub releases |
| ciphey-bin | GitHub releases |
| hypnotix-wayland | GitHub tags |
| libfprint-goodix-53xc | manual (Dell .deb, no feed) |
| python-pywhat | PyPI |
| rain | GitHub releases |
| rain-bin | GitHub releases |
| subdomainizer | GitHub releases |
| subrake | GitHub releases |

## How it works

```
nvchecker (daily) ──► bump PR ──► CI build + test ──► you merge ──► push to AUR
```

1. **Check** ([check.yml](.github/workflows/check.yml), daily or manual): `ci/check.py` takes the
   current `pkgver` of each package from its `.SRCINFO` and runs nvchecker with
   [nvchecker.toml](nvchecker.toml). No state is kept between runs, the repo is the state.
2. **Bump**: for each outdated package, `ci/bump.sh` sets `pkgver`, resets `pkgrel=1`, runs
   `updpkgsums` and regenerates `.SRCINFO`, then a PR is opened on branch `update/<pkg>`.
   If that PR is already open it gets updated in place, never duplicated.
3. **Test** ([test.yml](.github/workflows/test.yml), every PR plus a weekly rebuild of everything):
   `ci/build.sh` runs in a clean `archlinux:base-devel` container. It checks `.SRCINFO` is in sync,
   builds and installs with `paru` (so AUR dependencies work), runs namcap (informational only),
   then runs the package's `test.sh`.
4. **Review and merge.** Prefer merge commits: squashing a PR that imports a package flattens
   its AUR history.
5. **Publish** ([publish.yml](.github/workflows/publish.yml), on push to `master`): `ci/publish.sh`
   copies each changed package dir into its AUR repo as one commit, reusing the commit message,
   and pushes. `test.sh` is stripped and never reaches AUR. To re-publish a package by hand,
   run the workflow from the Actions tab with its name.

## Layout

```
<pkg>/            one dir per package, named after the pkgbase, with full AUR history
  PKGBUILD
  .SRCINFO
  test.sh         GitHub only, stripped on publish
nvchecker.toml    one section per package dir
ci/               scripts used by the workflows, runnable locally
```

## Tests

`<pkg>/test.sh` runs after the package is installed, as an unprivileged user, with
`bash -euxo pipefail`. `$pkgname` and `$pkgver` are set. Any non-zero exit fails the PR.

```sh
[ "$(rain -v)" = "Rain v$pkgver linux/amd64" ]
```

Keep them cheap smoke tests: version output, `--help`, an import. A package without `test.sh`
is only built and installed.

Run the whole thing locally, same as CI:

```sh
docker run --rm -v "$PWD:/repo:ro" archlinux:base-devel /repo/ci/build.sh rain
```

## Adding a package

```sh
git subtree add --prefix=<pkg> https://aur.archlinux.org/<pkg>.git master   # keeps AUR history
```

Or create the dir by hand for a brand new package. Then:

- Add `# Contributor: pusi77-robot <pusineriandrea+gmail+com>` to the PKGBUILD.
- Add a section to `nvchecker.toml` with the same name as the dir. The version it reports must
  equal `pkgver` exactly: use `prefix = "v"`, `include_regex`, `from_pattern`/`to_pattern` as
  needed. Check with `ci/check.py`, which prints the packages it would bump.
- Write a `test.sh` and add it with `git add -f`: the `.gitignore` that AUR repos usually ship
  whitelists only `PKGBUILD` and `.SRCINFO`, so git would silently skip it.
- On AUR, add `pusi77-robot` as co-maintainer, or the publish push is refused.

## Setup

Repository secrets:

| Secret | What |
|---|---|
| `AUR_SSH_KEY` | Private SSH key (no passphrase) of the `pusi77-robot` AUR account. |
| `PR_TOKEN` | Fine-grained PAT for this repo with *Contents* and *Pull requests* read/write. PRs opened with the default `GITHUB_TOKEN` don't trigger CI. |

## Caveats

- Anything pushed to AUR outside this repo (a co-maintainer, a manual push) is overwritten by the next publish.
- `PR_TOKEN` expires. When it does, the check workflow fails and update PRs stop.
- GitHub disables scheduled workflows after 60 days without repo activity. If update PRs stop appearing, re-enable `check.yml` in the Actions tab.
