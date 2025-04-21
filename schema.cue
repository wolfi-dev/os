@jsonschema(schema="https://json-schema.org/draft/2020-12/schema")
@jsonschema(id="https://chainguard.dev/melange/pkg/config/configuration")
#Configuration

#BaseImageDescriptor: close({
	image?:    string
	apkindex?: string
})

// BuildOption describes an optional deviation to a package build.
#BuildOption: close({
	Vars!: close({
		[string]: string
	})
	Environment!: #EnvironmentOption
})

// CPE stores values used to produce a CPE to describe the
// package, suitable for matching against NVD records.
#CPE: close({
	part?:       string
	vendor?:     string
	product?:    string
	edition?:    string
	language?:   string
	sw_edition?: string
	target_sw?:  string
	target_hw?:  string
	other?:      string
})

// Capabilities is the configuration for Linux capabilities for
// the runner.
#Capabilities: close({
	// Linux process capabilities to add to the pipeline container.
	add?: [...string]

	// Linux process capabilities to drop from the pipeline container.
	drop?: [...string]
})

#Checks: close({
	// Optional: disable these linters that are not enabled by
	// default.
	disabled?: [...string]
})

// Configuration is the root melange configuration.
#Configuration: close({
	// Package metadata
	package!: #Package

	// The specification for the packages build environment
	// Optional: environment variables to override apko
	environment?: #ImageConfiguration

	// Optional: Linux capabilities configuration to apply to the
	// melange runner.
	capabilities?: #Capabilities

	// Required: The list of pipelines that produce the package.
	pipeline?: [...#Pipeline]

	// Optional: The list of subpackages that this package also
	// produces.
	subpackages?: [...#Subpackage]

	// Optional: An arbitrary list of data that can be used via
	// templating in the
	// pipeline
	data?: [...#RangeData]

	// Optional: The update block determining how this package is auto
	// updated
	update?: #Update

	// Optional: A map of arbitrary variables that can be used via
	// templating in
	// the pipeline
	vars?: close({
		[string]: string
	})

	// Optional: A list of transformations to create for the builtin
	// template
	// variables
	"var-transforms"?: [...#VarTransforms]

	// Optional: Deviations to the build
	options?: close({
		[string]: #BuildOption
	})

	// Test section for the main package.
	test?: #Test
})

// ContentsOption describes an optional deviation to an apko
// environment's contents block.
#ContentsOption: close({
	Packages!: #ListOption
})

#Copyright: close({
	// Optional: The license paths, typically '*'
	paths?: [...string]

	// Optional: Attestations of the license
	attestation?: string

	// Required: The license for this package
	license!: string

	// Optional: Path to text of the custom License Ref
	"license-path"?: string
})

#DataItems: close({
	[string]: string
})

#Dependencies: close({
	// Optional: List of runtime dependencies
	runtime?: [...string]

	// Optional: List of packages provided
	provides?: [...string]

	// Optional: List of replace objectives
	replaces?: [...string]

	// Optional: An integer string compared against other equal
	// package provides used to
	// determine priority of provides
	"provider-priority"?: string

	// Optional: An integer string compared against other equal
	// package provides used to
	// determine priority of file replacements
	"replaces-priority"?: string
})

// EnvironmentOption describes an optional deviation to an apko
// environment.
#EnvironmentOption: close({
	Contents!: #ContentsOption
})

// GitHubMonitor indicates using the GitHub API
#GitHubMonitor: close({
	// Org/repo for GitHub
	identifier!: string

	// If the version in GitHub contains a prefix which should be
	// ignored
	"strip-prefix"?: string

	// If the version in GitHub contains a suffix which should be
	// ignored
	"strip-suffix"?: string

	// Filter to apply when searching tags on a GitHub repository
	// Deprecated: Use TagFilterPrefix instead
	"tag-filter"?: string

	// Prefix filter to apply when searching tags on a GitHub
	// repository
	"tag-filter-prefix"?: string

	// Filter to apply when searching tags on a GitHub repository
	"tag-filter-contains"?: string

	// Override the default of using a GitHub release to identify
	// related tag to
	// fetch. Not all projects use GitHub releases but just use tags
	"use-tag"?: bool
})

// GitMonitor indicates using Git
#GitMonitor: close({
	// StripPrefix is the prefix to strip from the version
	"strip-prefix"?: string

	// If the version in GitHub contains a suffix which should be
	// ignored
	"strip-suffix"?: string

	// Prefix filter to apply when searching tags on a GitHub
	// repository
	"tag-filter-prefix"?: string

	// Filter to apply when searching tags on a GitHub repository
	"tag-filter-contains"?: string
})

#Group: close({
	groupname?: string
	gid?:       int
	members?: [...string]
})

#ImageAccounts: close({
	"run-as"?: string
	users?: [...#User]
	groups?: [...#Group]
})

#ImageConfiguration: close({
	contents?:      #ImageContents
	entrypoint?:    #ImageEntrypoint
	cmd?:           string
	"stop-signal"?: string
	"work-dir"?:    string
	accounts?:      #ImageAccounts
	archs?: [...string]
	environment?: close({
		[string]: string
	})
	paths?: [...#PathMutation]
	"vcs-url"?: string
	annotations?: close({
		[string]: string
	})
	include?: string
	volumes?: [...string]
	layering?: #Layering
})

#ImageContents: close({
	build_repositories?: [...string]
	repositories?: [...string]
	keyring?: [...string]
	packages?: [...string]
	baseimage?: #BaseImageDescriptor
})

#ImageEntrypoint: close({
	type?:             string
	command?:          string
	"shell-fragment"?: string
	services?: close({
		[string]: string
	})
})

#Input: close({
	// Optional: The human-readable description of the input
	description?: string

	// Optional: The default value of the input. Required when the
	// input is.
	default?: string

	// Optional: A toggle denoting whether the input is required or
	// not
	required?: bool
})

#Layering: close({
	strategy?: string
	budget?:   int
})

// ListOption describes an optional deviation to a list, for
// example, a list of packages.
#ListOption: close({
	Add!: [...string]
	Remove!: [...string]
})

#Needs: close({
	// A list of packages needed by this pipeline
	Packages!: [...string]
})

#Package: close({
	// The name of the package
	name!: string

	// The version of the package
	version!: string

	// The monotone increasing epoch of the package
	epoch!: int

	// A human-readable description of the package
	description?: string

	// Annotations for this package
	annotations?: close({
		[string]: string
	})

	// The URL to the package's homepage
	url?: string

	// Optional: The git commit of the package build configuration
	commit?: string

	// List of target architectures for which this package should be
	// build for
	"target-architecture"?: [...string]

	// The list of copyrights for this package
	copyright?: [...#Copyright]

	// List of packages to depends on
	dependencies?: #Dependencies

	// Optional: Options that alter the packages behavior
	options?: #PackageOption

	// Optional: Executable scripts that run at various stages of the
	// package
	// lifecycle, triggered by configurable events
	scriptlets?: #Scriptlets

	// Optional: enabling, disabling, and configuration of build
	// checks
	checks?: #Checks

	// The CPE field values to be used for matching against NVD
	// vulnerability
	// records, if known.
	cpe?: #CPE

	// Optional: The amount of time to allow this build to take before
	// timing out.
	timeout?: int

	// Optional: Resources to allocate to the build.
	resources?: #Resources
})

#PackageOption: close({
	// Optional: Signify this package as a virtual package which does
	// not provide
	// any files, executables, libraries, etc... and is otherwise
	// empty
	"no-provides"?: bool

	// Optional: Mark this package as a self contained package that
	// does not
	// depend on any other package
	"no-depends"?: bool

	// Optional: Mark this package as not providing any executables
	"no-commands"?: bool
})

#PathMutation: close({
	path?:        string
	type?:        string
	uid?:         int
	gid?:         int
	permissions?: int
	source?:      string
	recursive?:   bool
})

#Pipeline: close({
	// Optional: A condition to evaluate before running the pipeline
	if?: string

	// Optional: A user defined name for the pipeline
	name?: string

	// Optional: A named reusable pipeline to run
	//
	// This can be either a pipeline builtin to melange, or a user
	// defined named pipeline.
	// For example, to use a builtin melange pipeline:
	// uses: autoconf/make
	uses?: string

	// Optional: Arguments passed to the reusable pipelines defined in
	// `uses`
	with?: close({
		[string]: string
	})

	// Optional: The command to run using the builder's shell
	// (/bin/sh)
	runs?: string

	// Optional: The list of pipelines to run.
	//
	// Each pipeline runs in its own context that is not shared
	// between other
	// pipelines. To share context between pipelines, nest a pipeline
	// within an
	// existing pipeline. This can be useful when you wish to share
	// common
	// configuration, such as an alternative `working-directory`.
	pipeline?: [...#Pipeline]

	// Optional: A map of inputs to the pipeline
	inputs?: close({
		[string]: #Input
	})

	// Optional: Configuration to determine any explicit dependencies
	// this pipeline may have
	needs?: #Needs

	// Optional: Labels to apply to the pipeline
	label?: string

	// Optional: Assertions to evaluate whether the pipeline was
	// successful
	assertions?: #PipelineAssertions

	// Optional: The working directory of the pipeline
	//
	// This defaults to the guests' build workspace (/home/build)
	"working-directory"?: string

	// Optional: environment variables to override apko
	environment?: close({
		[string]: string
	})
})

#PipelineAssertions: close({
	// The number (an int) of required steps that must complete
	// successfully
	// within the asserted pipeline.
	"required-steps"?: int
})

#RangeData: close({
	name!:  string
	items!: #DataItems
})

// ReleaseMonitor indicates using the API for
// https://release-monitoring.org/
#ReleaseMonitor: close({
	// Required: ID number for release monitor
	identifier!: int

	// If the version in release monitor contains a prefix which
	// should be ignored
	"strip-prefix"?: string

	// If the version in release monitor contains a suffix which
	// should be ignored
	"strip-suffix"?: string

	// Filter to apply when searching version on a Release Monitoring
	"version-filter-contains"?: string

	// Filter to apply when searching version Release Monitoring
	"version-filter-prefix"?: string
})

#Resources: close({
	cpu?:      string
	cpumodel?: string
	memory?:   string
	disk?:     string
})

// Schedule defines the schedule for the update check to run
#Schedule: close({
	// The reason scheduling is being used
	reason?: string
	period?: string
})

#Scriptlets: close({
	// Optional: A script to run on a custom trigger
	trigger?: #Trigger

	// Optional: The script to run pre install. The script should
	// contain the
	// shebang interpreter.
	"pre-install"?: string

	// Optional: The script to run post install. The script should
	// contain the
	// shebang interpreter.
	"post-install"?: string

	// Optional: The script to run before uninstalling. The script
	// should contain
	// the shebang interpreter.
	"pre-deinstall"?: string

	// Optional: The script to run after uninstalling. The script
	// should contain
	// the shebang interpreter.
	"post-deinstall"?: string

	// Optional: The script to run before upgrading. The script should
	// contain
	// the shebang interpreter.
	"pre-upgrade"?: string

	// Optional: The script to run after upgrading. The script should
	// contain the
	// shebang interpreter.
	"post-upgrade"?: string
})

#Subpackage: close({
	// Optional: A conditional statement to evaluate for the
	// subpackage
	if?: string

	// Optional: The iterable used to generate multiple subpackages
	range?: string

	// Required: Name of the subpackage
	name!: string

	// Optional: The list of pipelines that produce subpackage.
	pipeline?: [...#Pipeline]

	// Optional: List of packages to depend on
	dependencies?: #Dependencies

	// Optional: Options that alter the packages behavior
	options?:    #PackageOption
	scriptlets?: #Scriptlets

	// Optional: The human readable description of the subpackage
	description?: string

	// Optional: The URL to the package's homepage
	url?: string

	// Optional: The git commit of the subpackage build configuration
	commit?: string

	// Optional: enabling, disabling, and configuration of build
	// checks
	checks?: #Checks

	// Test section for the subpackage.
	test?: #Test
})

#Test: close({
	// Additional Environment necessary for test.
	// Environment.Contents.Packages automatically get
	// package.dependencies.runtime added to it. So, if your test
	// needs
	// no additional packages, you can leave it blank.
	// Optional: Additional Environment the test needs to run
	environment?: #ImageConfiguration

	// Required: The list of pipelines that test the produced package.
	pipeline!: [...#Pipeline]
})

#Trigger: close({
	// Optional: The script to run
	script?: string

	// Optional: The list of paths to monitor to trigger the script
	paths?: [...string]
})

// Update provides information used to describe how to keep the
// package up to date
#Update: close({
	// Toggle if updates should occur
	enabled!: bool

	// Indicates that this package should be manually updated, usually
	// taking
	// care over special version numbers
	manual?: bool

	// Indicates that automated pull requests should be merged in
	// order rather than superseding and closing previous unmerged
	// PRs
	"require-sequential"?: bool

	// Indicate that an update to this package requires an epoch bump
	// of
	// downstream dependencies, e.g. golang, java
	shared?: bool

	// Override the version separator if it is nonstandard
	"version-separator"?: string

	// A slice of regex patterns to match an upstream version and
	// ignore
	"ignore-regex-patterns"?: [...string]

	// The configuration block for updates tracked via
	// release-monitoring.org
	"release-monitor"?: #ReleaseMonitor

	// The configuration block for updates tracked via the Github API
	github?: #GitHubMonitor

	// The configuration block for updates tracked via Git
	git?: #GitMonitor

	// The configuration block for transforming the `package.version`
	// into an APK version
	"version-transform"?: [...#VersionTransform]

	// ExcludeReason is required if enabled=false, to explain why
	// updates are disabled.
	"exclude-reason"?: string

	// Schedule defines the schedule for the update check to run
	schedule?: #Schedule

	// Optional: Disables filtering of common pre-release tags
	"enable-prerelease-tags"?: bool
})

#User: close({
	username?: string
	uid?:      int
	gid?:      int
	shell?:    string
	homedir?:  string
})

#VarTransforms: close({
	// Required: The original template variable.
	//
	// Example: ${{package.version}}
	from!: string

	// Required: The regular expression to match against the `from`
	// variable
	match!: string

	// Required: The repl to replace on all `match` matches
	replace!: string

	// Required: The name of the new variable to create
	//
	// Example: mangeled-package-version
	to!: string
})

// VersionTransform allows mapping the package version to an APK
// version
#VersionTransform: close({
	// Required: The regular expression to match against the
	// `package.version` variable
	match!: string

	// Required: The repl to replace on all `match` matches
	replace!: string
})
