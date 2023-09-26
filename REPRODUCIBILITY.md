# Wolfi and Reproducibility

It is the intention of the Wolfi maintainers that all Wolfi packages are
reproducible.  We have designed our build tooling from the ground up to
facilitate this, for example, Melange builds packages using a declaratively
configured container built with apko.

There are presently some caveats, however:

- Packages may or may not reliably reproduce when built with newer
  dependencies.  We plan to add a `melange build --reproduce-from [sbom]`
  option to pin packages to the versions specified in an SBOM's build
  environment declaration as part of Melange 0.3.

- The Wolfi signing key is not public, for obvious reasons.
  You can swap signatures on an APKv2 package using [abuild-reusesig
  by kpcyrd][kpcyrd-reusesig].

   [kpcyrd-reusesig]: https://github.com/kpcyrd/abuild-reusesig

- Older packages in Wolfi were built with `-D_FORTIFY_SOURCE=2` and will
  not reproduce since we moved to `-D_FORTIFY_SOURCE=3` at present.  We
  plan to capture the `CFLAGS` and other relevant variables into the build
  environment SBOM section in the future to help mitigate this.  At the
  same time, we moved to `-march=x86-64-v2` and `-mtune=broadwell`, which
  while improving performance, will also break reproducibility with older
  packages since the `CFLAGS` were not captured.  Not all packages have yet
  been rebuilt with the new `CFLAGS`.

# Reproducing the entire OS

The easiest way to verify reproducibility in the build system is to
simply build the OS twice with the same key.  Or you can download the
entire Wolfi package collection using `gsutil -m rsync`:

    gsutil -m rsync gs://wolfi-production-registry-destination/os/ wolfi-packages/os/

If you download the Wolfi package collection, you will need to use the
`abuild-reusesig` tool to copy the Wolfi package signatures to your own
rebuilt packages.

Once you have two builds and the signatures have been normalized, you can
use a tool like diffoscope to verify the packages are reproducible by
comparing the package directories.

# Reproducing individual Wolfi packages

If you just want to test an individual Wolfi package for reproducibility,
the same caveats above still apply. For example, with `execline`:

    # doas make package/execline
    ...
    # doas mv packages packages-1
    # doas make package/execline
    ...
    # doas mv packages packages-2
    # sha256sum packages-1/$(uname -m)/*.apk | sed -e s:packages-1:packages-2:g | sha256sum -c
    packages2/x86_64/execline-2.9.0.1-r0.apk: OK
    packages2/x86_64/execline-dev-2.9.0.1-r0.apk: OK

The dependency packages will be sourced from the Wolfi repository
instead.

# Reproducibility as a requirement for package acceptance

In the future, we plan to require proof of reproducibility in order to
accept packages into the Wolfi package repository.  This requirement will
be rolled out alongside Melange 0.3 in early 2023, and will be tested as
part of the CI checks.
