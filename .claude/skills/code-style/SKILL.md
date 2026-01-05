---
name: code-style
description: Use when editing YAML files, working with package versioning, formatting, or creating PRs. Provides code style and formatting guidelines.
---

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
