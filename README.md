![wolfi logo](https://github.com/wolfi-dev/.github/raw/main/profile/wolfi-logo-dark-mode.svg#gh-dark-mode-only)
![wolfi logo](https://github.com/wolfi-dev/.github/raw/main/profile/wolfi-logo-light-mode.svg#gh-light-mode-only)

# Wolfi

This is the main package repository for the Wolfi project.

Named after the [smallest octopus][wiki-ow], [Wolfi][wolfi] is a lightweight GNU
software distribution which is designed around minimalism, making it
well-suited for containerized environments built with [apko][apko].

It is built using [melange][melange], and is sponsored by [Chainguard][cg],
which uses it to provide [lightweight GNU/Linux runtime images][cgi].

   [wiki-ow]: https://en.wikipedia.org/wiki/Octopus_wolfi
   [wolfi]: https://wolfi.dev
   [apko]: https://github.com/chainguard-dev/apko
   [melange]: https://github.com/chainguard-dev/melange
   [cg]: https://chainguard.dev/
   [cgi]: https://chainguard.dev/chainguard-images

The Wolfi APK package repository is located at https://packages.wolfi.dev/os and the signing public key is at https://packages.wolfi.dev/os/wolfi-signing.rsa.pub.

## Getting Started

A full guide is available on the [org page](https://github.com/wolfi-dev), but the quickest way to try out Wolfi is with the
[wolfi-base image](https://github.com/chainguard-images/images/tree/main/images/wolfi-base):

```
docker run -it cgr.dev/chainguard/wolfi-base
52aace776b20:/# uname -a
Linux 52aace776b20 5.15.49-linuxkit-pr #1 SMP PREEMPT Thu May 25 07:27:39 UTC 2023 aarch64 Linux
52aace776b20:/# cat /etc/os-release
ID=wolfi
NAME="Wolfi"
PRETTY_NAME="Wolfi"
VERSION_ID="20230201"
HOME_URL="https://wolfi.dev"
```

## Mixing packages with other distributions

Mixing packages with other distributions is not supported and can create security problems. Although both Wolfi and Alpine use the apk package manager, packages are not compatible with each other.

## If Wolfi is missing a package you require

We intend for Wolfi to be the core foundation of Chainguard OS and available as an open source project for use with minimal packages as used in our free Chainguard Containers.

Wolfi is not currently intended to be a general purpose operating system, and we are not accepting new package requests at this time. If you're a Chainguard Images customer, please reach out to your account team or submit a support ticket in console so we can prioritize your needs appropriately.
