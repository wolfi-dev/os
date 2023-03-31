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

    b. For the new patch, add a `patch` pipeline item in the `pipeline` YAML section. For example, if we downloaded a patch called `CVE-2018-25032.patch` to our package directory above, we'd add an item to `pipeline` that looks like this:

    ```yaml
    - uses: patch
      with:
        patches: CVE-2018-25032.patch
    ```

    For more information on how `patch` works, see [its definition](https://github.com/chainguard-dev/melange/blob/main/pkg/build/pipelines/patch.yaml).

    c. Add the advisories data to denote that the updated package version will fix the vulnerability. You can do this using [wolfictl](https://github.com/wolfi-dev/wolfictl/):


    ```sh
    wolfictl advisory create <path-to-melange-config.yaml> --vuln <CVE> --status 'fixed' --fixed-version <new-release-version> --sync
    ```

    For example, if we're patching CVE-2018-25032 in the "zlib" package, where the `version` is `1.2.3` and the `epoch` is 4, we'd run:

    ```sh
    wolfictl advisory create ./zlib.yaml --vuln 'CVE-2018-25032' --status 'fixed' --fixed-version '1.2.3-r4' --sync
    ```

1. In the [Makefile](./Makefile), find the line that corresponds to this package, and update the package version to our new release version from the Melange file.

1. Verify that our update package will build successfully by running Melange. To do this, run (in a container if you're not already on Linux):

    ```shell
    doas make
    ```

    Note that currently, this will build the **entire world**. If you want to build just a single package, first ensure that you have a `doas` configuration line that passes the `BUILDWORLD` variable through similar to this:
    ```
    permit setenv { BUILDWORLD=$BUILDWORLD } ...
    ```

    Then you can run the following to build the package:

    ```shell
    BUILDWORLD=no doas make packages/${ARCH}/${PACKAGE_NAME}-${PACKAGE_VERSION}.apk
    ```

1. Open a PR.

## NACKing a CVE

To NACK a CVE for a given package, we don't add in any patches or increment the package version. Instead, we just need to update the advisory data to say that this package is not affected by the vulnerability. As we do this, we also need to provide an accurate ["justification"](https://github.com/chainguard-dev/vex/blob/main/pkg/vex/justification.go#L12-L49) value as to why our package isn't affected. (And, if possible, we should also provide an "impact statement" that explains why we believe our package is not affected—but this is optional.)

For example:

```sh
wolfictl advisory create ./zlib.yaml --vuln 'CVE-2023-12345' --status 'not_affected' --justification 'vulnerable_code_not_present' --impact 'Fixed upstream prior to Wolfi packaging.' --sync
```

This will notify vulnerability scanners that consume our secdb that this vulnerabitiliy doesn't apply to any of the versions of this package that we've published.
