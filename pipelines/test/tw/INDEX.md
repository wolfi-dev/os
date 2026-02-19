# Test Pipelines Index

This directory contains test pipelines for validating Wolfi packages. Use this index to find the appropriate pipeline for your testing needs.

## Quick Reference

| Pipeline | Purpose | Required Inputs |
|----------|---------|-----------------|
| `contains-files` | Verify package contains expected files | `files` or `dir`+`name` |
| `debugpackage` | Validate debug symbol packages | none |
| `devpackage` | Validate development packages | none |
| `docs` | Validate documentation packages | none |
| `emptypackage` | Validate empty packages | none |
| `gem-check` | Verify Ruby gems load correctly | none |
| `header-check` | Verify C/C++ headers compile | none |
| `help-check` | Verify binaries respond to --help | `bins` |
| `ldd-check` | Check for missing shared libraries | none |
| `metapackage` | Validate meta-packages (deps only) | none |
| `no-docs` | Ensure package has no documentation | none |
| `pip-check` | Validate Python package dependencies | none |
| `shell-deps.check` | Check shell scripts for missing commands | `files` |
| `shell-deps-check-packages` | Check package shell scripts for deps | `package` |
| `staticpackage` | Validate static library packages | none |
| `symlink-check` | Verify symlinks are valid | none |
| `byproductpackage` | Validate by-product packages | none |
| `ver-check` | Verify binaries report correct version | `bins` |
| `verify-service` | Validate systemd service files | none |
| `virtualpackage` | Validate virtual package providers | `virtual-pkg-name` |

---

## Package Type Validation

Use these pipelines to validate that packages conform to expected structural patterns for their type.

### `docs`
Validates documentation packages contain only documentation files under a specified path prefix.

**When to use:** For `-doc` packages that should only contain documentation.

**Inputs:**
- `path-prefix` (optional, default: `usr/share`) - Expected path prefix for docs

---

### `devpackage`
Validates development packages contain headers, static libraries, and development files.

**When to use:** For `-dev` or `-devel` packages.

**Inputs:** None

---

### `staticpackage`
Validates packages contain only static libraries (`.a` files).

**When to use:** For `-static` packages.

**Inputs:** None

---

### `debugpackage`
Validates debug symbol packages contain appropriate debug information.

**When to use:** For `-dbg` or `-debug` packages.

**Inputs:** None

---

### `emptypackage`
Validates packages are empty (minimal package definition).

**When to use:** For packages that intentionally contain no files.

**Inputs:** None

---

### `metapackage`
Validates meta-packages that contain only dependencies, no files.

**When to use:** For packages that exist solely to group dependencies.

**Inputs:** None

---

### `byproductpackage`
Validates by-product packages created during build.

**When to use:** For automatically generated split/companion packages.

**Inputs:** None

---

### `virtualpackage`
Validates packages provide specified virtual capabilities.

**When to use:** For packages that provide virtual package names (e.g., `provides: mail-transport-agent`).

**Inputs:**
- `virtual-pkg-name` (required) - Space-separated list of virtual package names to verify

**Dependencies:** package-type-check, busybox

---

## Binary and Tool Validation

Use these pipelines to verify that binaries work correctly.

### `help-check`
Verifies binaries respond correctly to help flags (`--help`, `-h`, etc.).

**When to use:** To ensure CLI tools have working help output.

**Inputs:**
- `bins` (required) - Space-separated list of binaries to test
- `help-flag` (optional, default: `auto`) - Specific flag to test
- `expect-contains` (optional) - String that must appear in help output
- `verbose` (optional) - Enable verbose output

**Dependencies:** help-check

---

### `ver-check`
Verifies binaries report the correct version information.

**When to use:** To ensure CLI tools report the expected version.

**Inputs:**
- `bins` (required) - Space-separated list of binaries to test
- `version` (optional, default: `${{package.version}}`) - Expected version string
- `version-flag` (optional, default: `auto`) - Specific flag to test
- `match-type` (optional) - One of: `contains`, `exact`, `regex`
- `verbose` (optional) - Enable verbose output

**Dependencies:** ver-check

---

### `gem-check`
Validates Ruby gems can be properly required and loaded.

**When to use:** For Ruby gem packages to verify they install and load correctly.

**Inputs:**
- `package` (optional, default: `${{context.name}}`) - Package name
- `require` (optional) - Gem names to test (auto-detected if not specified)

**Dependencies:** gem-check

**Note:** Ruby/gem dependencies should be declared in the package itself.

---

## Dependency and Library Validation

Use these pipelines to check for dependency issues.

### `ldd-check`
Checks binaries for missing runtime library dependencies using `ldd`.

**When to use:** To verify all shared library dependencies are resolvable.

**Inputs:**
- `files` (optional) - Specific files to check
- `exclude-files` (optional) - Files to skip
- `packages` (optional, default: `${{context.name}}`) - Packages to check
- `extra-library-paths` (optional) - Additional library search paths
- `verbose` (optional) - Enable verbose output

**Dependencies:** ldd-check

---

### `pip-check`
Validates Python package dependencies using `pip check`.

**When to use:** For Python packages to verify no dependency version conflicts.

**Inputs:**
- `python` (optional, default: `DEFAULT`) - Python interpreter (auto-detected)

**Dependencies:** tw-pip-check

---

### `shell-deps.check`
Checks shell script files for missing command dependencies and GNU-specific flags incompatible with busybox.

**When to use:** When you have shell scripts and want to verify all commands they use are available.

**Inputs:**
- `files` (required) - Shell script files to check (supports glob patterns)
- `path` (optional, default: `/usr/bin`) - PATH to use for command lookup
- `strict` (optional, default: `true`) - Fail on any missing dependency
- `verbose` (optional) - Enable verbose output

**Dependencies:** tw

**Uses:** `tw shell-deps check`

---

### `shell-deps-check-packages`
Checks installed package shell scripts for dependency issues.

**When to use:** To verify shell scripts in an installed package have all required commands available.

**Inputs:**
- `package` (required) - Package name to check
- `path` (optional, default: `/usr/bin`) - PATH to use for command lookup
- `strict` (optional, default: `true`) - Fail on any missing dependency
- `verbose` (optional) - Enable verbose output

**Dependencies:** tw

**Uses:** `tw shell-deps check-package`

---

## File Structure and Content Validation

Use these pipelines to verify package contents.

### `header-check`
Verifies C/C++ header files compile successfully.

**When to use:** For packages with header files to ensure they have valid syntax and includes.

**Inputs:**
- `packages` (optional, default: `${{context.name}}`) - Packages to check
- `files` (optional) - Specific header files to test
- `configure-opts` (optional) - Additional compiler flags

**Dependencies:** header-check

---

### `symlink-check`
Verifies symlinks point to valid targets and checks for absolute symlinks.

**When to use:** To ensure no broken or problematic symlinks in packages.

**Inputs:**
- `packages` (optional, default: `${{context.name}}`) - Packages to check
- `allow-absolute` (optional, default: `false`) - Allow absolute symlinks

**Dependencies:** symlink-check

---

### `contains-files`
Verifies a package contains expected files.

**When to use:** To assert specific files exist in a package.

**Inputs (mode 1 - directory search):**
- `dir` (optional, default: `/usr/`) - Directory to search
- `name` (optional, default: `*`) - File name pattern (find syntax)
- `type` (optional, default: `f`) - File type (`f` for file, `d` for directory, etc.)

**Inputs (mode 2 - direct file check):**
- `files` (optional) - Space-separated list of file paths to verify exist

---

### `no-docs`
Ensures a package contains no documentation files.

**When to use:** For runtime-only or specialized packages that should not include docs.

**Inputs:**
- `package` (optional, default: `${{context.name}}`) - Package to check

**Dependencies:** no-docs-check

---

### `verify-service`
Validates systemd service/unit files for proper formatting and best practices.

**When to use:** For packages that install systemd services.

**Inputs:**
- `skip-files` (optional) - Space-separated files to exclude from validation
- `man` (optional, default: `false`) - Include documentation tests

**Dependencies:** verify-service

---

## Usage Examples

### Basic package type validation
```yaml
test:
  pipeline:
    - uses: test/tw/devpackage
```

### Binary version check
```yaml
test:
  pipeline:
    - uses: test/tw/ver-check
      with:
        bins: myapp mycli
```

### Check for required files
```yaml
test:
  pipeline:
    - uses: test/tw/contains-files
      with:
        files: /usr/bin/myapp /etc/myapp/config.yaml
```

### Shell script dependency check
```yaml
test:
  pipeline:
    - uses: test/tw/shell-deps-check-packages
      with:
        package: ${{package.name}}
```
