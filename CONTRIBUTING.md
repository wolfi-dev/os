# Contributing to wolfi-dev/os

* [Setup development environmment](#setup-development-environment)

## Setup development environment

To ease the development of Wofli OS, you can use `chainguard-images/sdk` container image that already include both [apko]() & [melange]().

To start a development environment, do

```sh
make dev-container
```

What it does is start the `chainguard-images/sdk` image and mount the current working directory into it.

Now, the `Makefile` script assume that there're melange folder & melange binary in there. I change it locally to the following because it's where they are in `chainguard-image/sdk`.

```
MELANGE_DIR ?= /usr/share/melange
MELANGE ?= $(shell which melange)
```

## Write your first Wolfi package

Wofie is using melange to build packages. If you want to learn the details what commands are used when building packages, they are in the [`ci-build.yaml`](.github/workflows/ci-build.yaml) and [Makefile](Makefile).

Start by creating a YAML file named `<your-package-name>.yaml` in the repo's root directory. If you have patches, create a folder with same name and put patches there.

Add a new entry for your package in Makefile like this

```
$(eval $(call build-package,<your-package-name>,<version>-r<epoch>))
```

Once you're done writing the new package, you can test building it with `make packages/<your-package-name>`.

## Some tips

- melange has a few pipelines included, ready to be used. You can see the the list & source code of the builtin pipelines [here in melange repo](https://github.com/chainguard-dev/melange/tree/main/pkg/build/pipelines).

- Make sure to pump the epoch if you're changing the package's build script without updating the version. Also reset the epoch back to 0 when you update the package version.

- You don't need to add `environment.contents.repositories` and `environment.contents.keyring`. Those are added automatically in the `ci-build.yaml` script during CI.

- For patching CVEs, you can follow the [documentation here](HOW_TO_PATCH_CVES.md).

- If you don't want to build all the packages locally, you can install `gsutil` and use it to sync the prebuilt packages from `gs://wolfi-production-registry-destination/os/` bucket: 

```sh
gsutil -m rsync -r gs://wolfi-production-registry-destination/os/ ./packages
```

- If you dont want to install `gsutil` locally, you can use this image `gcr.io/google.com/cloudsdktool/google-cloud-cli:slim` which is the official SDK image from GCP and already include `gsutil` in there.