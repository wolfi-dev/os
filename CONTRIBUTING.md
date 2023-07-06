# Contributing to wolfi-dev/os

<!-- toc -->
- [Setup development environment](#setup-development-environment)
- [Write your first Wolfi package](#write-your-first-wolfi-package)
- [Package versioning](#package-versioning)
- [Some tips](#some-tips)
<!-- /toc -->

## Setup development environment

To ease the development of Wolfi OS, you can use the [Wolfi `sdk` image](https://github.com/wolfi-dev/tools/pkgs/container/sdk) that already includes both [apko](https://github.com/chainguard-dev/apko) and [melange](https://github.com/chainguard-dev/melange).
On Linux and Mac it is also possible to install both the above tools directly into your system.

If you choose not to install the tooling onto your local machine, you can start a container based development environment using

```sh
make dev-container
```

What it does is start the `ghcr.io/wolfi-dev/sdk` image and mount the current working directory into it.

## Write your first Wolfi package

Wolfi packages are built using melange. If you want to learn how packages are built, you can see all the details in the [`ci-build`](.github/workflows/ci-build.yaml) workflow and in the [Makefile](Makefile).

Start by cloning this repository and create a YAML file named `<your-package-name>.yaml` in its root directory. If you have any patches, create a folder with the same name and put them there.

Once you're done writing the new package configuration file, you can test it by triggering a build with `make packages/<your-package-name> BUILDWORLD=no USE_CACHE=no`.

note: `USE_CACHE=no` disables using a GCP cloud bucket for caching pipeline sources.  This is mainly used for production setups and not needed for local development.

If you do use a cache for your sources and see GCS auth related errors, your gcloud auth credentials might be the issue. Try running `gcloud auth login && gcloud auth application-default login`.

Your build packages should be found in the generated `./packages` directory.

While you're here, you can scan the package you just built for vulnerabilities, such as by using an experimental [Grype](https://github.com/anchore/grype)-based scanning script we provide: `./scripts/grype-scan-apk.sh`.

```
./scripts/grype-scan-apk.sh packages/<arch>/<your-package-name-and-version>.apk
```

Check for anything unexpected, or for any [CVEs you can patch](./HOW_TO_PATCH_CVES.md).

## Package versioning

- When bumping version of a package, you will need to update the version, epoch & shasum (sha256 or sha512) in package YAML file. The version and epoch also need to be bumped in Makefile.

- `epoch` needs to be bump when package version remains the same but something else changes. `epoch` needs to be reset to 0 when it's a new version of the package.

- `melange` CLI has a command `bump` to make it easier. More details are [available here](https://github.com/chainguard-dev/melange/blob/f52b622351657fd9ccdb7e3bfb124caef61ad651/NEWS.md).

## Some tips

- melange has a few built-in pipelines. You can see their source code [in the melange repository](https://github.com/chainguard-dev/melange/tree/main/pkg/build/pipelines).

- You don't need to add `environment.contents.repositories` and `environment.contents.keyring`. Those are added automatically in the `ci-build.yaml` script during CI.

- For patching CVEs, you can follow the [documentation here](HOW_TO_PATCH_CVES.md).

- If you don't want to build all the packages locally, you can install `gsutil` and use it to sync the prebuilt packages from `gs://wolfi-production-registry-destination/os/` bucket:

```sh
gsutil -m rsync -r gs://wolfi-production-registry-destination/os/ ./packages
```

- If you dont want to install `gsutil` locally, you can use this image `gcr.io/google.com/cloudsdktool/google-cloud-cli:slim` which is the official SDK image from GCP and already include `gsutil` in there.

- When deciding how to add `update:` configuration see the [update docs](./docs/UPDATES.md)

- When you're ready to submit a PR for a new package or to update a package, make sure your YAML file(s) are **formatted correctly**, so that they'll pass CI. We use [yam](https://github.com/chainguard-dev/yam) for YAML formatting. You should be able to run the `yam` command from the root of this repo to get all files formatted correctly.

- When running a lot of melange builds using `docker` as a runner (default on Mac) you may want to increase the Docker VM CPU, Memory and especially storage resources, else Docker can easily run out of disk space.