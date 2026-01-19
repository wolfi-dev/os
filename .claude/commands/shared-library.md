# Shared Library Naming Pattern

Convert a package to use the shared library naming pattern to allow multiple versions to coexist during transitions.

## Pattern Overview

The shared library naming pattern involves:

1. **Add var-transforms** to create a soversion variable from the package version
2. **Rename library subpackages** to include the soversion (e.g., `libfoo` → `libfoo${{vars.soversion}}`)
3. **Update references** to use the versioned library names
4. **DO NOT add `provides`** to library subpackages (to allow co-installation)

## Steps to Apply

### 1. Add var-transforms or vars section

Add this after the `copyright` section (adjust the regex match pattern based on version format):

**Option A: Use var-transforms when the soversion can be derived from package version:**

```yaml
var-transforms:
  - from: ${{package.version}}
    match: ^(\d+)\.(\d+)$
    replace: ${1}.${2}.0
    to: soversion
```

Common patterns:
- For X.Y versions → `^(\d+)\.(\d+)$` → `${1}.${2}.0`
- For X.Y.Z versions extracting major → `^(\d+)\..*$` → `${1}`
- For X.Y.Z versions → `^(\d+)\.(\d+)\.(\d+)$` → `${1}.${2}.${3}`

**Option B: Use vars when the soversion doesn't match the package version:**

If the soname version (e.g., `libjemalloc.so.2`) doesn't map cleanly from the package version (e.g., `5.3.0`), use a direct variable:

```yaml
vars:
  soversion: "2"
```

### 2. Create or rename library subpackages

Use the `split/lib` pipeline to automatically split out shared libraries. The pipeline supports optional filtering via patterns.

**Single library subpackage (most common):**

Use this when a package provides one primary library or multiple libraries that are always used together:

```yaml
  - name: libfoo${{vars.soversion}}
    pipeline:
      - uses: split/lib
```

This automatically moves all `*.so.*` files from `lib/` and `usr/lib/` to the subpackage.

**Multiple library subpackages (filtering with patterns):**

Use this when a package provides multiple distinct libraries that should be in separate subpackages:

```yaml
  - name: libprotoc${{vars.soversion}}
    pipeline:
      - uses: split/lib
        with:
          patterns: protoc

  - name: libprotobuf${{vars.soversion}}
    pipeline:
      - uses: split/lib
        with:
          patterns: |
            protobuf
            protobuf-lite
```

The `patterns` input matches `lib<pattern>.so.*` for each pattern. For example:
- `protoc` matches `libprotoc*.so.*`
- `ssl` and `crypto` would match `libssl.so.*` and `libcrypto.so.*`

**Advanced: Custom library paths**

If libraries are in non-standard locations (beyond the default `lib/` and `usr/lib/`):

```yaml
  - name: libfoo${{vars.soversion}}
    pipeline:
      - uses: split/lib
        with:
          paths: |
            usr/lib64
            opt/lib
```

### 3. Runtime dependencies

**IMPORTANT:** Always add explicit versioned runtime dependencies from the `-dev` package to the versioned library packages.

While melange's SCA (Software Composition Analysis) can automatically detect dependencies, explicit runtime dependencies ensure:
- Clear dependency relationships in the package metadata
- Consistent behavior across package managers
- Easier tracking of package relationships

Add runtime dependencies to the `-dev` subpackage:

**Single library package:**
```yaml
subpackages:
  - name: ${{package.name}}-dev
    pipeline:
      - uses: split/dev
    dependencies:
      runtime:
        - ${{package.name}}${{vars.soversion}}=${{package.full-version}}
```

**Multiple library packages:**
```yaml
subpackages:
  - name: ${{package.name}}-dev
    pipeline:
      - uses: split/dev
    dependencies:
      runtime:
        - libprotoc${{vars.soversion}}=${{package.full-version}}
        - libprotobuf${{vars.soversion}}=${{package.full-version}}
        - libprotobuf-lite${{vars.soversion}}=${{package.full-version}}
```

The versioned dependency (e.g., `libfoo${{vars.soversion}}=${{package.full-version}}`) ensures that the -dev package always pulls in the exact library version at build time.

### 4. Update binary references (if applicable)

If the package installs versioned binaries (like protoc), update references:

```yaml
mv ${{targets.destdir}}/usr/bin/binary-${{vars.soversion}} ${{targets.subpkgdir}}/usr/bin/
```

### 5. Update tests (if applicable)

Update test references to use `${{vars.soversion}}` instead of hardcoded version strings.

### 6. Lint the file

Always run the linter after making changes:
```bash
./lint.sh <package-name>.yaml
```

## Examples

### Example 1: protobuf (X.Y version format, multiple libraries)

```yaml
package:
  name: protobuf
  version: "33.0"

var-transforms:
  - from: ${{package.version}}
    match: ^(\d+)\.(\d+)$
    replace: ${1}.${2}.0
    to: soversion

subpackages:
  - name: libprotoc${{vars.soversion}}
    pipeline:
      - uses: split/lib
        with:
          patterns: protoc

  - name: libprotobuf${{vars.soversion}}
    pipeline:
      - uses: split/lib
        with:
          patterns: protobuf

  - name: libprotobuf-lite${{vars.soversion}}
    pipeline:
      - uses: split/lib
        with:
          patterns: protobuf-lite

  - name: protobuf-dev
    pipeline:
      - uses: split/dev
    dependencies:
      runtime:
        - libprotoc${{vars.soversion}}=${{package.full-version}}
        - libprotobuf${{vars.soversion}}=${{package.full-version}}
        - libprotobuf-lite${{vars.soversion}}=${{package.full-version}}
```

### Example 2: fmt (X.Y.Z version format, single library)

```yaml
package:
  name: fmt
  version: "12.0.0"

var-transforms:
  - from: ${{package.version}}
    match: ^(\d+)\..*$
    replace: ${1}
    to: soversion

subpackages:
  - name: lib${{package.name}}${{vars.soversion}}
    pipeline:
      - uses: split/lib

  - name: ${{package.name}}-dev
    pipeline:
      - uses: split/dev
    dependencies:
      runtime:
        - lib${{package.name}}${{vars.soversion}}=${{package.full-version}}
```

### Example 3: jemalloc (soversion doesn't match package version)

```yaml
package:
  name: jemalloc
  version: 5.3.0

vars:
  soversion: "2"

subpackages:
  - name: libjemalloc${{vars.soversion}}
    pipeline:
      - uses: split/lib

  - name: jemalloc-dev
    pipeline:
      - uses: split/dev
    dependencies:
      runtime:
        - libjemalloc${{vars.soversion}}=${{package.full-version}}
```

In this case, the package provides `so:libjemalloc.so.2=2` but the version is `5.3.0`, so we use a direct `vars` declaration.

## Important Notes

- **DO NOT add `provides` declarations** to library subpackages - this allows multiple versions to coexist
- The main package and -dev package may have `provides` if needed for compatibility
- Using `${{package.name}}` in subpackage names is fine and can remain unchanged
- The key change is adding `${{vars.soversion}}` to library subpackage names
- Test that the package builds and installs correctly after the change
- This pattern is specifically for shared libraries (.so files), not for executables or other package types

## Task Instructions

When you invoke this command with a package name as an argument:

1. **Check the APK index** to understand what the package currently provides:
   ```bash
   # Fetch package info from APK index
   curl -sL https://apk.cgr.dev/chainguard/x86_64/APKINDEX.tar.gz | tar -xzOf - APKINDEX | grep -A 30 "^P:<package-name>$"
   ```
   Look for the `p:` line which shows provided sonames (e.g., `p:so:libisal.so.2=2`)

2. **Inspect the APK contents** to see what library files are included:
   ```bash
   # Check package contents for libraries
   curl -sL "https://apk.cgr.dev/chainguard/x86_64/<package-name>-<version>.apk" | tar -tzv | grep -E '\.(so|a)'
   ```
   This shows the actual .so files (e.g., `libisal.so.2.0.31`, `libisal.so.2`)

3. **Determine the soversion** from the soname:
   - If the package provides `so:libfoo.so.2`, the soversion should typically be `2`
   - Match this with the package version to create the appropriate var-transforms pattern

4. **Read the package YAML file** to understand current structure

5. **Identify all library subpackages** (those containing .so files)

6. **Determine the appropriate var-transforms pattern** based on the version format

7. **Apply all the transformations** listed in the steps above

8. **Run the linter** to ensure proper formatting:
   ```bash
   ./lint.sh <package-name>.yaml
   ```

9. **Summarize the changes made**, including:
   - What soname/version the package currently provides
   - The var-transforms pattern applied
   - The library subpackages created
   - Verification that linting passed

Example usage: `/shared-library <package-name>`
