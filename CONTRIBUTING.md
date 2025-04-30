# Contributing to wolfi-dev/os

<!-- toc -->
- [Criteria for packages in Wolfi](#criteria-for-packages-in-wolfi)
- [Setup development environment](#setup-development-environment)
- [Write your first Wolfi package](#write-your-first-wolfi-package)
- [Package versioning](#package-versioning)
- [Some tips](#some-tips)
<!-- /toc -->

## Criteria for packages in Wolfi

When you're thinking about adding a new package to Wolfi, make sure it meets all of the following criteria before taking the time to define, build, and test the package:

1. The package must use the latest version of the upstream project, and the package must **not** use a _pre-release_ version.
2. The package's upstream source must use an [OSI-approved](https://opensource.org/licenses) license.

In addition to the above, the Wolfi Maintainers reserve the right to reject other package contributions for other reasons, too. If you are unsure whether a particular package qualifies for acceptance into Wolfi, consider opening an issue on GitHub before putting time into the PR itself, and the maintainers will provide feedback as soon as possible.

## Setup development environment

To ease the development of Wolfi OS, you can use the [Wolfi `sdk` image](https://github.com/wolfi-dev/tools/pkgs/container/sdk) that already includes both [apko](https://github.com/chainguard-dev/apko) and [melange](https://github.com/chainguard-dev/melange).
On Linux and Mac it is also possible to install both the above tools directly into your system.

If you choose not to install the tooling onto your local machine, you can start a container based development environment using

```sh
make dev-container
```

What it does is start the `ghcr.io/wolfi-dev/sdk` image and mount the current working directory into it.

## Write your first Wolfi package

Wolfi packages are built using melange. If you want to learn how packages are built, you can see all the details in the [Makefile](Makefile).

Start by cloning this repository and create a build configuration YAML file named `<your-new-package-name>.yaml` in its root directory. If you have any patch files that are needed to build this package, create a folder at the root of the repository with the same name as the package and put the patches there.

Once you're done writing the new package configuration file, you can test it by building the new package.

## Building a package

To build an individual package, you can use a `make` command like this:

```text
make package/<your-new-package-name>
```

For example, if your package name is "foo", run `make package/foo`.

This will build the package by invoking [melange](https://github.com/chainguard-dev/melange) in a particular way. This invocation is defined in the [Makefile](Makefile), if you're interested to see how this is wired up. Also, you can run Melange _directly_ without using `make` if you understand what you're doing.

**Note:** The buildsystem has a cache of source files that may help reduce the time your build takes. Feel free to see if this cache helps you by adding `USE_CACHE=yes` to the command above. If you encounter issues with this approach, the best advice is to remove the `USE_CACHE=no` from your command and carry on with your builds.

When the build finishes, your package(s) should be found in the generated `./packages` directory.

## Scanning your package for vulnerabilities

While you're here, you can scan the package you just built for vulnerabilities, using [wolfictl](https://github.com/wolfi-dev/wolfictl)'s `scan` command:

```shell
wolfictl scan ./packages/some-architecture/your-package-name-and-version.apk
```

Check for anything unexpected, or for any [CVEs you can patch](./HOW_TO_PATCH_CVES.md).

## Package versioning

- When bumping version of a package, you will need to update the version, epoch & shasum (sha256 or sha512) in package YAML file. The version and epoch also need to be bumped in Makefile.

- `epoch` needs to be bumped when the package version remains the same but something else changes. `epoch` needs to be reset to 0 when it's a new version of the package.

- `melange` CLI has a command `bump` to make it easier. More details are [available here](https://github.com/chainguard-dev/melange/blob/main/docs/md/melange_bump.md).

## Some tips

- melange has a few built-in pipelines. You can see their source code [in the melange repository](https://github.com/chainguard-dev/melange/tree/main/pkg/build/pipelines).

- You don't need to add `environment.contents.repositories` and `environment.contents.keyring`. Those are added automatically.

- For patching CVEs, you can follow the [documentation here](HOW_TO_PATCH_CVES.md).

- When deciding how to add `update:` configuration see the [update docs](./docs/UPDATES.md)

- When you're ready to submit a PR for a new package or to update a package, make sure your YAML file(s) are **formatted correctly**, so that they'll pass CI. We use [yam](https://github.com/chainguard-dev/yam) for YAML formatting. You should be able to run the `yam` command from the root of this repo to get all files formatted correctly.

- When running a lot of melange builds using `docker` as a runner (default on Mac) you may want to increase the Docker VM CPU, Memory and especially storage resources, else Docker can easily run out of disk space.
