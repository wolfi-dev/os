---
name: build
description: Use when building packages, testing, linting, scanning for vulnerabilities, or running make commands. Provides all build system commands.
---

## Build Commands
- Set up QEMU runner (first time): `make fetch-kernel` (only needed once to download kernel files)
- Enable QEMU environment: `export QEMU_KERNEL_IMAGE=$(pwd)/kernel/boot/vmlinuz; export MELANGE_OPTS="--runner=qemu"`
- Build a package: `make package/<package-name>`
- Build with Docker (fallback): `make docker-package/<package-name>`
- Test a package: `make test/<package-name>`
- Debug test failures: `make test-debug/<package-name>` (requires a TTY)
- Lint YAML files: `./lint.sh [filename.yaml]`
- Run in dev container: `make dev-container`
- Scan for vulnerabilities: `wolfictl scan ./packages/$(uname -m)/<package-name-and-version>.apk`
- Explore APK contents: `tar tzv -f packages/$(uname -m)/<package-name-and-version>.apk`
