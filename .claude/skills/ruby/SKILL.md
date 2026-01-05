---
name: ruby
description: Use when working with Ruby packages, gems, or writing tests for Ruby packages. Provides Ruby-specific packaging guidelines, testing patterns, and best practices.
---

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
