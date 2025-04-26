# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands
- Set up QEMU runner (first time): `make fetch-kernel` (only needed once to download kernel files)
- Enable QEMU environment: `export QEMU_KERNEL_IMAGE=/tmp/kernel/boot/vmlinuz; export MELANGE_OPTS="--runner=qemu"`
- Build a package: `make package/<package-name>`
- Build with Docker (fallback): `make docker-package/<package-name>`
- Test a package: `make test/<package-name>`
- Debug test failures: `make test-debug/<package-name>` (requires a TTY)
- Lint YAML files: `./lint.sh [filename.yaml]`
- Run in dev container: `make dev-container`
- Scan for vulnerabilities: `wolfictl scan ./packages/$(uname -m)/<package-name-and-version>.apk`
- Explore APK contents: `tar tzv -f packages/$(uname -m)/<package-name-and-version>.apk`

## Code Style Guidelines
- Package YAML files follow strict formatting (enforced by `yam`)
- YAML fields: maintain alphabetical order when possible
- Package versioning: increment "epoch" when changing a package without version bump
- Reset "epoch" to 0 for new package versions
- PR naming: `<package-name>/<version>: <description>`
- Package updates may contain an `update:` section for automation
- When patching CVEs: use `<CVE-ID>.patch` naming convention
- Security fixes must be recorded in the advisories repo
- Version streams: use version string in package name, provide logical unversioned forms

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

## Ruby Package Guidelines

When working with Ruby packages:

- Always increment the epoch when updating a package
- When adding a test, add it to all Ruby version variants (e.g., ruby3.2-*, ruby3.3-*, ruby3.4-*)
- Test environment should include ruby-${{vars.rubyMM}} and any direct dependencies
- Typical testing pattern for gems:
  ```yaml
  test:
    environment:
      contents:
        packages:
          - ruby-${{vars.rubyMM}}
    pipeline:
      - name: Verify library loading
        runs: |
          ruby -e "require 'gem_name'; puts 'Successfully loaded gem'"
      - name: Verify functionality
        runs: |
          ruby <<-EOF
          require 'gem_name'
          # Basic functionality test
          EOF
  ```
- For dependencies, check if they actually need to be specified in the test environment or if they are already included via package dependencies
- Common issue: missing gem dependencies often result in loading errors at test time
