# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commit Guidelines
- Never commit directly to the main branch; always create a feature branch
- Each commit should fix one issue or update one package
- Format: `<package-name>: <concise description of change>`
- For version updates: `<package-name>/<version> package update`
- Keep the first line under 72 characters
- Use the imperative mood ("Add feature" not "Added feature")
- Describe what changed and why, not how
- When fixing build failures, explain the cause of the failure and the solution
- For multiple related packages, separate with commas: `pkg1, pkg2: <description>`
- Do not include "Co-Authored-By" lines unless specifically requested

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

## Code Style Guidelines
- Package YAML files follow strict formatting (enforced by `yam`)
- YAML fields: maintain alphabetical order when possible
- Remove all trailing whitespace from files
- Ensure consistent indentation (2 spaces for YAML)
- Package versioning: increment "epoch" when changing a package without version bump
- Reset "epoch" to 0 for new package versions
- PR naming: `<package-name>/<version>: <description>`
- Package updates may contain an `update:` section for automation
- When patching CVEs: use `<CVE-ID>.patch` naming convention
- Security fixes must be recorded in the advisories repo
- Version streams: use version string in package name, provide logical unversioned forms
- ALWAYS run `./lint.sh <filename.yaml>` after updating any YAML file to ensure proper formatting
- Avoid removing comments unless they are no longer accurate.

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
- Use the test/tw/gem-check pipeline step when appropriate to verify gem installation
- Implement thorough testing for gem functionality, not just loading

### Testing Ruby Packages

#### Basic Testing Structure
```yaml
test:
  environment:
    contents:
      packages:
        - ruby-${{vars.rubyMM}}
  pipeline:
    - uses: test/tw/gem-check  # Verify gem installation
    - name: Verify library loading
      runs: |
        ruby -e "require 'gem_name'; puts 'Successfully loaded gem'"
    - name: Test basic functionality
      runs: |
        ruby <<-EOF
        require 'gem_name'

        begin
          # Actual functionality tests with sample inputs and expected outputs
          # Use raise to fail the test on unexpected results
          puts "All tests passed!"
        rescue => e
          puts "Test failed: \#{e.message}"
          exit 1
        end
        EOF
```

#### Testing Best Practices
- Always read `pipelines/test` to learn what test pipelines are available.
- CRITICAL: Always test the ACTUAL PACKAGE that is being built, not just its dependencies
- Ensure tests exercise the main functionality that users of the gem would use
- Include comprehensive tests that verify actual gem functionality, not just loading
- Test with realistic inputs and verify expected outputs
- Use begin/rescue blocks to handle errors and provide informative failure messages
- Test edge cases and parameter variations where applicable
- For CLI tools, verify command execution (e.g., `rspec --version`)
- Group related tests into logical sections with clear pass/fail messages
- If a gem has optional parameters (like bias, ignore flags), test those too when possible
- Use exit code 1 to indicate test failures
- Validate that key classes, methods, and constants from the package are present and working
- Write tests that verify command behavior, not just execution
- When adding tests, always review existing tests and avoid creating redundant tests.
- When a command is expected to fail, explicitly check for an error code and fail if the command passes.
- Use your understanding of the package under test to determine the core functionality to validate
- All shell code should be compatible with busybox, not bash-specific features
- When including multiple shell commands, organize them into semantic groupings with comments (if logical grouping exists) or sort them alphabetically
- For shell condition checks, use direct comparison with `[ "$OUTPUT" = "expected" ]` style
- The test environment is ephemeral, any non-zero exit code indicates a failure, you do not need to explicitly validate exit codes unless they are relevant to the test
- For numeric outputs, use appropriate numeric comparisons like `[ "$COUNT" -eq 3 ]`
- When matching patterns in complex outputs, use variable expansion with grep but without the error exit: `[ "$(echo "$OUTPUT" | grep "pattern")" != "" ]`

### Avoiding Fragile Tests
- For version checks, simply run `--version` without validating the output at all
- Never validate specific version numbers in tests, even when using `${{package.version}}` interpolation
  - Version number formats may change (e.g., from "1.2" to "v1.2.0")
  - Additional information may be added to version outputs between releases
  - Patch releases may include suffixes or build information that break exact matches
- When testing CLI programs, focus only on successful execution of commands
- For version and help commands, verify:
  - The command runs successfully (non-zero exit code would fail the test naturally)
  - For extremely important elements, check their presence very loosely with pattern matching
- Focus exclusively on testing behavior and functionality, not output format or content
- For help text, at most verify that key commands appear somewhere in the output
- If you must check for output content, use very minimal pattern matching looking for single keywords

#### Common Testing Mistakes to Avoid
- Testing a dependency instead of the actual package being built
- Only testing that a gem can be loaded without testing any functionality
- Missing required dependencies in the test environment
- Testing trivial aspects while ignoring core functionality
- Failing to handle errors or provide useful error messages

#### Dependencies
- For dependencies, check if they actually need to be specified in the test environment or if they are already included via package dependencies
- Common issue: missing gem dependencies often result in loading errors at test time
- Test that expected dependencies are present and correctly loaded
