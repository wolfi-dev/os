# CI Checks for Wolfi Packages

## Overview
This document explains the Continuous Integration (CI) check that verifies packages updates in Wolfi. 

# CI Build Actions

The main build has two jobs that compile the package(s) for both x86 and arm architectures. This check is a cornerstone of our CI pipeline, ensuring that every package can successfully build across platforms.

### When It Fails

1. Consult the Logs: 

The logs usually contain detailed information about why the build failed. The quality of logs can vary depending on the language ecosystem or the build tool being used.

2. Check for Melange Lint Warnings

Look for warnings or failures from [Melange lint](https://github.com/chainguard-dev/melange/blob/main/docs/LINTER.md) at the end of the build log for each package. These could give clues to what went wrong.


# Wolfi Check Updates

Each PR will automatically trigger a `Package Update Config Check` job. This
validates that the information specified in the `update:` section of the package
definition (melange yaml), is correct, and aims to catch any issues our
automation may face checking for future package updates.

If this job fails, the PR will not be merged, and the root cause will need to
be investigated and rectified.

### When It Fails

Please validate your configuration and settings in the `update:` block are
correct. This will need to be remediated before the contribution will be
accepted.

The most common cause for issues tend to be when an upstream project adds new tags or releases that are used for development or debugging.  To fix this we can include `ignore-regex-patterns`, for example:

https://github.com/wolfi-dev/os/blob/645d1b93bfe5e34197e6db006cea7477851b9352/libapr.yaml#L70-L71
```
update:
  enabled: true
  ignore-regex-patterns:
    - '.*x-.*'
  ...
```

Another common scenario, may be when a project doesn't cut GitHub releases, and
only publishes Git tags. For such projects, you'll need to specify
`use-tag: true` in the update block.

# Wolfi Lint

The Wolfi project has some specific rules around how a melange yaml file should look.  This includes things like

- yaml formatting
- inclusion of license headers
- forbidden repositories
- forbidden keyrings
- no repeated package dependencies

For a full list or to contribute more see [here](https://github.com/wolfi-dev/wolfictl/blob/79d21a2bbc2f682b6df8cf46c955257dca545367/pkg/lint/rules.go#L38)

### When It Fails

You can run the same CI check locally to help iterate and fix failed lint rules.

Using [wolfictl](https://github.com/wolfi-dev/wolfictl) you can run

```
wolfictl lint
```

# So name
This CI check is particularly important for ensuring that ABI (Application Binary Interface) compatibility is not broken when updating shared object versions.

This check exists to make sure that package updates are backward-compatible and won't break dependent packages. For example, when a shared object version is bumped, it may require dependent packages to be updated as well. **This is crucial for maintaining the stability of our systems**.

### When It Fails?
If this CI check fails, it's usually because of a new major shared object version that's been introduced with a package update. In this case, you'll need to bump the epoch field in the YAML files of downstream dependent packages.

## What to do when the so name check fails


The action required here is to bump the epoch for all the downstream dependent packages. The "epoch" is a field in the package's YAML file that needs to be incremented when a new major shared object version is introduced.

1. **Find the downstream dependent packages**: Find the affected YAML files in your PR. Use GitHub search to identify packages that use your updated package.

2. **Locate and update the epoch field**: The epoch field is usually towards the top of the YAML file. You'll need to increment the value by one. For example, if the current value is `0`, you would change it to `1`.

```yaml
package:
  name: libfoo
  epoch: 0 // need to increment this by one
```

3. **Push changes:** Push these changes to the same PR that has the failing so name check. This ensures the build can compile all packages that use the package which introduces the new shared object file version.

4. **Confirm and label:** Once it's confirmed that downstream packages are being built with this new version of the shared object, add the soname-validate label to the PR. This signals to the Wolfi Maintainer admin that they can review, approve, and merge by overriding the failed check.

> **Note:** The So-Name CI check will still fail after all the above steps are completed. This is expected behavior, and a Wolfi Maintainer admin will need to override the failed check.

Example PR: https://github.com/wolfi-dev/os/pull/20198

In this example PR, we can see there is a new shared object version being introduced in the `gsl` package. The `gsl.yaml` file has four packages: `gsl`, `gsl-dev`, `gsl-doc`, and `gsl-static`.

To find the dependent packages of `gsl`, we use [GitHub search](https://github.com/search?q=repo:wolfi-dev/os%20gsl&type=code). In this case, we can see that there are two packages that are dependent on the `gsl-dev` package: `dieharder` and `lsb-release-minimal`. 

Therefore, we need to increment the epoch of these two dependent packages. To do this, locate the epoch field in the YAML files of `dieharder` and `lsb-release-minimal`, and increment the value by one.

> **Note:** We do not need to increment the epoch of the `gsl` package itself, as it is the package that is introducing the new shared object version.

# Wolfi Scan

One of the core missions of the The Wolfi project is to produce packaged software with low or no CVEs.  To help us achieve this we have a check that is a wrapper around [Grype](https://github.com/anchore/grype) to help scan proposed packages before they are merged to main.  This is not a required CI check yet, but helps contributors know if packages the are suggesting help with the Wolfi mission.

## How to Fix

You can run the same CI check locally to help iterate and patch failed scans.

First build the Wolfi package locally using an extra melange option

```
MELANGE_EXTRA_OPTS="--create-build-log"
```

This will create a `packages.log` file once the packages have been built.

Next, using [wolfictl](https://github.com/wolfi-dev/wolfictl) you can run

```
wolfictl scan .  --build-log
```

Typically a vulnerability is reported against a dependency of the package you are building.  Depending on what type of package you have there are different approaches used to patch the software.

1. Go

You can update the go modules of a package in the melange pipeline, adding notes of what CVEs the patch addresses and helps maintainers remove these patches when upstream releases them.

Example: https://github.com/wolfi-dev/os/pull/7299/files

2. C

Check the upstream project to find if there's already a patch, this can happen if the upstream project has not yet released a new version with the CVE fix.

Create a folder in the root of the Wolfi repo that matches the package name.  Add the patch using a filename that matches the CVE.

Example: https://github.com/wolfi-dev/os/blob/6d578fb/zlib/CVE-2023-45853.patch

Using the build-in melange `patch` [pipeline](https://github.com/chainguard-dev/melange/blob/main/pkg/build/pipelines/patch.yaml) you can apply your patch making sure to add a reference where the patch comes from.

```
  - uses: patch
    with:
      # Patch source: https://patch-diff.githubusercontent.com/raw/madler/zlib/pull/843.patch
      patches: CVE-2023-45853.patch
```