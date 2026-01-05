# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Available Skills

This project uses Claude skills to provide specialized guidance. 
The following skills are automatically activated when relevant or otherwise you should read the skill and use it:

| Skill | Use When |
|-------|----------|
| `git` | Committing changes, creating PRs, working with git |
| `build` | Building packages, testing, linting, scanning for vulnerabilities |
| `code-style` | Editing YAML files, package versioning, formatting |
| `packaging` | Creating new packages, understanding package structure, debugging builds, working with melange |
| `ruby` | Working with Ruby packages, gems, or Ruby package tests |

NOTE: You must update our list of skills whenever you create or edit a skill.

# Some Resources
1. The cwd contains a lot of packages, which are in form of yaml. This yaml is actually powered by melange, which is an opensource tool and its code and docs are available at /Users/kaustubh/Documents/chainguard/melange. In addition, you can refer /Users/kaustubh/Documents/chainguard/melange/pkg/build/pipelines for pipelines of different types.

# How to Package
1. First and foremost use the packaging skill (read guidelines at ./.claude/skills/packaging/SKILL.md) -- this is the ultumate start.
2. Then we focus on what we are packaging, if its a new open source project, its best to see the project and what kind of project is it (go, python etc...), what is the Makefile and Dockerfile saying. Can use packaging-repo-explorer agent for this.
3. Then find similar 5-6 mellage packages -- i.e. their yamls -- in this repo and learn from them. Refer mellange documentation further to refer to how things work + what is the best way to package.
4. Plan the packaging and present it to the user, and in the last step implement the packaging.
5. It's then the user's job right now to test it and tell you if anything is failing.

# Current Work
We are working towards creating a new package for this project: /Users/kaustubh/Documents/chainguard/source-watcher
You can reference the directory and the project for packaging.
