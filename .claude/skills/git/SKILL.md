---
name: git
description: Use when committing changes, creating PRs, or working with git in this repository. Provides commit message format, branch guidelines, and PR naming conventions.
---

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
