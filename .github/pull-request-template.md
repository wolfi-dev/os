<!---
Provide a short summary in the Title above. Examples of good PR titles:
* "ruby-3.1: new package"
* "haproxy: fix CVE-2014-123456"
-->

<!--
Please include references to any related issues or delete this section otherwise.
 -->

Fixes:

Related:

### Pre-review Checklist

<!--
This checklist is mostly useful as a reminder of small things that can easily be
forgotten – it is meant as a helpful tool rather than hoops to jump through.

At the moment of this PR you have the most information on what all the change
will affect, so please take the time to jot it down.

Put an `x` in all the items that apply, make notes next to any that haven't been
addressed, and remove any items that are not relevant to this PR.

-->

#### For new package PRs only
<!-- remove if unrelated -->
- [ ] This PR is marked as fixing a pre-existing package request bug
  - [ ] Alternatively, the PR is marked as related to a pre-existing package request bug, such as a dependency
- [ ] REQUIRED - The package is available under an OSI-approved or FSF-approved license
- [ ] REQUIRED - The version of the package is still receiving security updates
- [ ] This PR links to the upstream project's support policy (e.g. `endoflife.date`)

#### For new version streams
<!-- remove if unrelated -->
- [ ] The upstream project actually supports multiple concurrent versions.
- [ ] Any subpackages include the version string in their package name (e.g. `name: ${{package.name}}-compat`)
- [ ] The package (and subpackages) `provides:` logical unversioned forms of the package (e.g. `nodejs`, `nodejs-lts`)
- [ ] If non-streamed package names no longer built, open PR to withdraw them (see [WITHDRAWING PACKAGES](https://github.com/wolfi-dev/os/blob/main/WITHDRAWING_PACKAGES.md))

#### For package updates (renames) in the base images
<!-- remove if unrelated -->
When updating packages part of base images (i.e. cgr.dev/chainguard/wolfi-base or ghcr.io/wolfi-dev/sdk)
- [ ] REQUIRED cgr.dev/chainguard/wolfi-base and ghcr.io/wolfi-dev/sdk images successfully build
- [ ] REQUIRED cgr.dev/chainguard/wolfi-base and ghcr.io/wolfi-dev/sdk contain no obsolete (no longer built) packages
- [ ] Upon launch, does `apk upgrade --latest` successfully upgrades packages or performs no actions

#### For security-related PRs
<!-- remove if unrelated -->
- [ ] The security fix is recorded in the [advisories](https://github.com/wolfi-dev/advisories) repo

#### For version bump PRs
<!-- remove if unrelated -->
- [ ] The `epoch` field is reset to 0

#### For PRs that add patches
<!-- remove if unrelated -->
- [ ] Patch source is documented
