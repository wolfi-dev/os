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

1. Add the advisories data to denote that the updated package version will fix the vulnerability. This is done using [wolfictl](https://github.com/wolfi-dev/wolfictl/).

    **Note:** You'll need to have already cloned the [Wolfi Advisories](https://github.com/wolfi-dev/advisories) repo locally. We recommend you clone it to a sibling directory to where you've cloned this (`os`) repo (e.g., you'd end up with `.../foo/os` and `.../foo/advisories`.)

    Run `wolfictl adv create` (or, if an advisory for this CVE is already present, run `wolfictl adv update`).

    ```console
    $ wolfictl adv create
    Auto-detected distro: Wolfi

    Package: █
    Type to find a package. Ctrl+C to quit.
    ```

    From there, follow the prompts. The exact prompts will change from time to time as we iterate on the system, but the general flow should be intuitive.

    For example, if we're patching CVE-2018-25032 in the "zlib" package, where the version is 1.2.3 and the epoch is 4, we'd enter `zlib` as the package, `CVE-2018-25032` as the vulnerability and `1.2.3-r4` as the fixed version.

1. Verify that our update package will build successfully by running Melange. To do this, run (in a container if you're not already on Linux):

    ```shell
    make
    ```

    Note that currently, this will build the **entire world**. If you want to build just a single package, you can run the following to build the package:

    ```shell
    make package/${PACKAGE_NAME}
    ```

1. Open a PR.

## NACKing a CVE

To NACK a CVE for a given package, we don't add in any patches or increment the package version. Instead, we just need to update the advisory data to say that this package is not affected by the vulnerability. As we do this, we also need to provide an accurate ["justification"](https://github.com/chainguard-dev/vex/blob/main/pkg/vex/justification.go#L12-L49) value as to why our package isn't affected.

Recording the NACK is done with the `wolfictl adv create` command (or `wolfictl adv update` if an advisory already exists for this package and CVE).

For example:

```console
$ wolfictl adv create
Auto-detected distro: Wolfi

Package: zlib
Vulnerability: CVE-2023-77777
Status:
  not_affected
Justification:
  vulnerable_code_not_present
```

This will notify vulnerability scanners that consume our secdb that this vulnerabitiliy doesn't apply to any of the versions of this package that we've published.

## Language Specific Tips

### Go

For go apps, we often bump dependencies to pick up fixes.
There are a few ways to do this, but most typically involve running the `go get` command with a specific version.

This can be done inside a `runs` block in a melange pipeline, or using the `deps` feature of the `go/build` pipeline.

To do it manually (in the `runs` block), use something like this:

```yaml
go get golang.org/x/text@v0.3.8
go mod tidy
```

Note that this must come **after** the source has been fetched, and **before** the build takes place.

You typically need a `go mod tidy` at the end of a series of `go get` invocations.

If the app uses a `vendor` directory (this is rare), you'll need to run `go mod vendor` instead of `go mod tidy`.

These steps usually work, but occassionaly dependencies can become tangled and you'll need to bump a few more before you can bump the one you want to get a build to work.

In these cases it's best to clone the app and test it all locally outside of melange.

If you get stuck, ask for help!

### Java

Java apps mostly use either maven or gradle, which use different version declaration schemes.

If you're patching a vulnerable dependency, you'll first need to figure out which package manager you're using.

From there, you can manually edit the file (either `pom.xml` or `build.gradle`) to contain the new version.

After that, test the build and package as usual, and generate a `.patch` file, following the instructions above.

In some cases, you might also be able to get away with using a `sed` command instead of generating a patch file.
