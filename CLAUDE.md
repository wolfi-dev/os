# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands
- Set up QEMU runner (first time): `make fetch-kernel` (only needed once to download kernel files)
- Enable QEMU environment: `export QEMU_KERNEL_IMAGE=$(pwd)/kernel/boot/vmlinuz; export MELANGE_OPTS="--runner=qemu"`
- Build a package: `make package/<package-name>`
- Build with Docker (fallback): `make docker-package/<package-name>`
- Test a package: `make test/<package-name>`
- Debug test failures: `make test-debug/<package-name>`
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

