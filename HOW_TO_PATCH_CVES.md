# How To Patch CVEs

The process of patching Wolfi APK packages for reported CVEs

## Steps

For the ease of explanation, we'll assume we're addressing a single reported vulnerability for a single package.

1. Determine the vulnerability's CVE ID. (e.g. "CVE-2018-25032")

1. Locate the best patch for the affected software.

    a. If possible, find a patch in the "upstream" repo for this software, linked from the vulnerability report itself (e.g. from `https://nvd.nist.gov/vuln/detail/<CVE-ID>`).

    b. If an upstream patch is not available, look to see how other Linux distros have handled patching for this CVE. (Tip: Alpine and Fedora are both pretty good at patching!)

    c. It's possible that patching is not possible or not appropriate for the situation. If the vulnerability has never been exploitable in this package, you can "NACK" (negatively acknowledge) this CVE for this package. See [NACKing a CVE](#nacking-a-cve) for instructions, and skip all remaining steps.

1. In your local clone of this repo, create a top-level directory using the name of the affected package, if such a directory doesn't already exist.

1. Download the patch into this package directory. The patch's file name should be in the form of `<CVE-ID>.patch` (e.g. `CVE-2018-25032.patch`).

1. In the Melange YAML file for this package (back in the root of the repo), make the following updates:

    a. Increment the "epoch" value. (e.g. change from `2` to `3`)

    b. Add the "secfixes" data to denote that the updated package version will fix the vulnerability. If the `secfixes` top-level YAML field doesn't already exist, create it.

    For example, to show that a new version (e.g. `...-r3` if we just incremented "epoch" to `3`) fixes CVE-2022-37434, the YAML might look like this:

    ```yaml
    secfixes:
      1.2.12-r3:
        - CVE-2022-37434
    ```

    c. For the new patch, add a `patch` pipeline item in the `pipeline` YAML section. For example, if we downloaded a patch called `CVE-2018-25032.patch` to our package directory above, we'd add an item to `pipeline` that looks like this:

    ```yaml
    - uses: patch
      with:
        patches: CVE-2018-25032.patch
    ```

    For more information on how `patch` works, see [its definition](https://github.com/chainguard-dev/melange/blob/main/pipelines/patch.yaml).

1. In the [Makefile](./Makefile), find the line that corresponds to this package, and update the package version to our new release version from the Melange file.

1. Verify that our update package will build successfully by running Melange.

1. Open a PR.

## NACKing a CVE

To NACK a CVE for a given package, we don't add in any patches or increment the package version. Instead, the only thing we do is add a special entry to the `secfixes` section of the Melange YAML file, where we use a `0` in place of a real version of this package. For example:

```yaml
secfixes:
  0:
    - CVE-2019-6293
```

This will notify vulnerability scanners that consume our secdb that this vulnerabitiliy doesn't apply to any of the versions of this package that we've published.
