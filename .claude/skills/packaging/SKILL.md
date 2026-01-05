---
name: packaging
description: Use when creating new packages, understanding package structure, debugging builds, or working with melange. Provides packaging guidelines and debugging tips.
---

## File Structure
Package definitions are YAML files with build instructions for Melange.

## Packages
Built apk packages end up in the packages/ subdirectory, with an APKINDEX for each architecture.
The file structure inside these can be examimed with the `tar` command.

Packages in this repository are used to build container images.
When packaging a piece of software, look at existing Dockerfiles in the repository for the piece of software you're packaging to understand what files need to be packaged and how they should be laid out.

Split documentation into a separate subpackage where possible.

Try to reuse existing melange pipelines where possible.

## Debugging

When debugging failed builds, try cloning the source code from the melange file locally to a directory here to study the build system.

## Other General notes
Follow the previously mentioned notes as a baseline, and then also consider these additional notes:
- Certain packages are a bit weird, like Java and Python. Make sure to check existing examples, but especially note the following:
  - Use py3.x-supported-y packages whenever possible
  - Use a modern and supported JVM/JDK version (making sure to pick the right packages as well) and loading the environment variables properly
  - Avoid using obsolete package versions
- It is worthwhile to search for similar packages to use as working examples over generating something entirely new.
