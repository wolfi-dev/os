# Now in Stereo!
#
# Useful environment variables:
#
# - ARCH - One of aarch64 or x86_64; run the make on and for this architecture;
#          running aarch64 on x86 is *extremely* slow, so you probably want to
#          use an ARM Workstation instead. Defaults to the current architecture.
#
# - MELANGE_EXTRA_OPTS - Extra command-line options to pass to melange.
#
# - MELANGE_RUNNER - Runner used to build/test packages. One of qemu, docker,
#                    or bubblewrap. qemu is usually the best choice, bubblewrap
#                    uses less resources, and docker might be required for some
#                    tests to work. We should make that consistent.
#
# - MELANGE_TMPDIR - Directory for melange cache and build files. Defaults to
#                    $TMPDIR or /tmp if that isn't set.
#
# Useful make targets:
#
# - make debug/{foo} - Builds the {foo} package in debug mode; if a pipeline
#                      command fails, you'll be dropped into a shell running
#                      inside the container for further investigation.
#
# - make local-wolfi - Boot a local container with access to and locally-built
#                      APKs.
#
# - make package/{foo} - Builds the {foo} package.
#
# - make test/{foo} - Tests the {foo} package; if you have a local APK built,
#                     it'll test with that, otherwise it will download it from
#                     the package repo.
#
# - make test-debug/{foo} - Tests the {foo} package in debug mode; if a test
#                           pipeline command fails, you'll be dropped into a
#                           shell running inside the container for debugging.

ARCH ?= $(shell uname -m)
ifeq ($(ARCH), arm64)
	ARCH = aarch64
else ifeq ($(ARCH), amd64)
	ARCH = x86_64
endif

MELANGE_TMPDIR := $(if $(MELANGE_TMPDIR),$(MELANGE_TMPDIR),$(if $(TMPDIR),$(TMPDIR),/tmp))
CACHEDIR = $(MELANGE_TMPDIR)/melange-cache
TARGETDIR = packages/$(ARCH)

MELANGE ?= $(shell which melange)
WOLFICTL ?= $(shell which wolfictl)
KEY ?= local-melange.rsa
REPO ?= $(shell pwd)/packages
QEMU_KERNEL_REPO := https://apk.cgr.dev/chainguard-private/

MELANGE_RUNNER ?= qemu
MELANGE_OPTS += --runner=$(MELANGE_RUNNER)
MELANGE_TEST_OPTS += --runner=$(MELANGE_RUNNER)
QEMU_KERNEL_IMAGE ?= kernel/$(ARCH)/vmlinuz
ifeq ($(MELANGE_RUNNER),qemu)
	QEMU_KERNEL_DEP = $(QEMU_KERNEL_IMAGE)
	export QEMU_KERNEL_IMAGE
endif

MELANGE_OPTS += --apk-cache-dir=$(CACHEDIR)
MELANGE_OPTS += --arch=$(ARCH)
MELANGE_OPTS += --cache-dir=$(CACHEDIR)
MELANGE_OPTS += --cleanup
MELANGE_OPTS += --env-file=build-$(ARCH).env
MELANGE_OPTS += --env-file=build-common.env
MELANGE_OPTS += --git-repo-url=https://github.com/wolfi-dev/os
MELANGE_OPTS += --keyring-append=$(KEY).pub
MELANGE_OPTS += --license=Apache-2.0
MELANGE_OPTS += --namespace=wolfi
MELANGE_OPTS += --package-append=busybox
MELANGE_OPTS += --pipeline-dir=./pipelines/
MELANGE_OPTS += --repository-append=$(REPO)
MELANGE_OPTS += --signing-key=$(KEY)
MELANGE_OPTS += $(MELANGE_EXTRA_OPTS)

# Enter interactive mode on failure for debug
MELANGE_DEBUG_OPTS += --debug
MELANGE_DEBUG_OPTS += --interactive
MELANGE_DEBUG_OPTS += --package-append=apk-tools
MELANGE_DEBUG_OPTS += $(MELANGE_OPTS)

# Enter interactive mode on test failure for debug
MELANGE_DEBUG_TEST_OPTS += --interactive

# These are separate from MELANGE_OPTS because for building we need additional
# ones that are not defined for tests.
MELANGE_TEST_OPTS += --repository-append=$(REPO)
MELANGE_TEST_OPTS += --keyring-append=$(KEY).pub
MELANGE_TEST_OPTS += --arch=$(ARCH)
MELANGE_TEST_OPTS += --pipeline-dirs=./pipelines/
MELANGE_TEST_OPTS += --repository-append=https://packages.wolfi.dev/os
MELANGE_TEST_OPTS += --keyring-append=https://packages.wolfi.dev/os/wolfi-signing.rsa.pub
MELANGE_TEST_OPTS += --test-package-append=wolfi-base
MELANGE_TEST_OPTS += --debug
MELANGE_TEST_OPTS += $(MELANGE_EXTRA_OPTS)

ifeq ($(LINT), yes)
	MELANGE_OPTS += --fail-on-lint-warning
endif

BOOTSTRAP_REPO ?= https://packages.wolfi.dev/bootstrap/stage3
BOOTSTRAP_KEY ?= https://packages.wolfi.dev/bootstrap/stage3/wolfi-signing.rsa.pub
WOLFI_REPO ?= https://packages.wolfi.dev/os
WOLFI_KEY ?= https://packages.wolfi.dev/os/wolfi-signing.rsa.pub
BOOTSTRAP ?= no

SOURCE_DATE_EPOCH := $(shell git --no-pager log -1 --pretty=%ct 2>/dev/null || jj log -r @ --no-graph -T 'committer.timestamp().utc().format("%s")' 2>/dev/null || echo 0)
ifeq ($(SOURCE_DATE_EPOCH),0)
  $(error setting SOURCE_DATE_EPOCH failed - $(SOURCE_DATE_EPOCH))
endif
export SOURCE_DATE_EPOCH

DOCKER_PLATFORM_ARG := $(shell \
  case $(ARCH) in \
	(aarch64) darch=arm64;; \
	(x86_64) darch=amd64;; \
	(*) echo "unknown-docker-platform-arch-$(ARCH)"; exit 1;; \
  esac ; \
  echo "--platform=linux/$$darch" \
)

ifeq ($(BOOTSTRAP), yes)
	MELANGE_OPTS += --keyring-append=$(BOOTSTRAP_KEY)
	MELANGE_OPTS += --repository-append=$(BOOTSTRAP_REPO)
else
	MELANGE_OPTS += --keyring-append=$(WOLFI_KEY)
	MELANGE_OPTS += --repository-append=$(WOLFI_REPO)
endif

$(KEY):
	$(MELANGE) keygen $(KEY)

.PHONY: cache
cache:
	mkdir -p $(CACHEDIR)

.PHONY: clean
clean:
	rm -rf packages/$(ARCH)
	rm -rf kernel/

.PHONY: clean-cache
clean-cache:
	rm -rf $(CACHEDIR)

.PHONY: fetch-kernel
fetch-kernel:
	rm -rf kernel/$(ARCH)
	$(MAKE) kernel/$(ARCH)/vmlinuz

kernel/%/APKINDEX.tar.gz:
	@$(call authget,apk.cgr.dev,$@,$(QEMU_KERNEL_REPO)/$(ARCH)/APKINDEX.tar.gz)

kernel/%/APKINDEX: kernel/%/APKINDEX.tar.gz
	tar -x -C kernel --to-stdout -f $< APKINDEX > $@.tmp.$$$$ && mv $@.tmp.$$$$ $@
	touch $@

kernel/%/chosen: kernel/%/APKINDEX
	# Extract lines with 'P:linux-qemu-melange' and the following line that contains the version
	# This approach is compatible with both GNU and BSD sed
	awk '/^P:linux-qemu-melange$$/ {print; getline; print}' $< > kernel/$*/available
	grep '^V:' kernel/$*/available | sed 's/V://' | \
		sort -V | tail -n1 > $@.tmp
	# Sanity check that this looks like an apk version
	grep -E '^([0-9]+\.)+[0-9]+-r[0-9]+$$' $@.tmp
	mv $@.tmp $@

kernel/%/linux.apk: kernel/%/chosen
	@$(call authget,apk.cgr.dev,$@,$(QEMU_KERNEL_REPO)/$*/linux-qemu-melange-$(shell cat kernel/$*/chosen).apk)

kernel/%/vmlinuz: kernel/%/linux.apk
	tmpd=kernel/.$$$$ && mkdir -p $$tmpd $(dir $@) && \
		tar -x -C $$tmpd -f $< boot/ 2> /dev/null && \
		[ -f $$tmpd/boot/vmlinuz ] && mv $$tmpd/boot/* $(dir $@) && \
		rc=$$?; rm -Rf $$tmpd; exit $$rc
	touch $@

yamls := $(wildcard *.yaml)
pkgs := $(subst .yaml,,$(yamls))
pkg_targets = $(foreach name,$(pkgs),package/$(name))
$(pkg_targets): package/%: cache
	$(eval yamlfile := $*.yaml)
	$(eval pkgver := $(shell $(MELANGE) package-version $(yamlfile)))
	@printf "Building package $* with version $(pkgver) from file $(yamlfile)\n"
	$(MAKE) yamlfile=$(yamlfile) pkgname=$* packages/$(ARCH)/$(pkgver).apk

packages/$(ARCH)/%.apk: $(KEY) $(QEMU_KERNEL_DEP) $(yamlfile)
	@[ -n "$(pkgname)" ] || { echo "$@: pkgname is not set"; exit 1; }
	@[ -n "$(yamlfile)" ] || { echo "$@: yamlfile is not set"; exit 1; }
	mkdir -p ./$(pkgname)/
	$(MELANGE) build $(yamlfile) $(MELANGE_OPTS) --source-dir=./$(pkgname)/

docker_pkg_targets = $(foreach name,$(pkgs),docker-package/$(name))
$(docker_pkg_targets): docker-package/%:
	@echo "Building using docker runner"
	MELANGE_RUNNER=docker make package/$*

dbg_targets = $(foreach name,$(pkgs),debug/$(name))
$(dbg_targets): debug/%: cache $(KEY) $(QEMU_KERNEL_DEP)
	$(eval yamlfile := $*.yaml)
	$(eval pkgver := $(shell $(MELANGE) package-version $(yamlfile)))
	@printf "Building package $* with version $(pkgver) from file $(yamlfile)\n"
	mkdir -p ./"$*"/
	$(call set_source_date_epoch $(yamlfile))
	$(MELANGE) build $(yamlfile) $(MELANGE_DEBUG_OPTS) --source-dir=./$(*)/

test_targets = $(foreach name,$(pkgs),test/$(name))
$(test_targets): test/%: cache $(KEY) $(QEMU_KERNEL_DEP)
	mkdir -p ./$(*)/
	$(eval yamlfile := $*.yaml)
	$(eval pkgver := $(shell $(MELANGE) package-version $(yamlfile)))
	@printf "Testing package $* with version $(pkgver) from file $(yamlfile)\n"
	$(MELANGE) test $(yamlfile) $(MELANGE_TEST_OPTS) --source-dir=./$(*)/

docker_test_targets = $(foreach name,$(pkgs),docker-test/$(name))
$(docker_test_targets): docker-test/%:
	@echo "Testing using docker runner"
	MELANGE_RUNNER=docker make test/$*

testdbg_targets = $(foreach name,$(pkgs),test-debug/$(name))
$(testdbg_targets): test-debug/%: cache $(KEY) $(QEMU_KERNEL_DEP)
	mkdir -p ./$(*)/
	$(eval yamlfile := $*.yaml)
	$(eval pkgver := $(shell $(MELANGE) package-version $(yamlfile)))
	@printf "Testing package $* with version $(pkgver) from file $(yamlfile)\n"
	$(MELANGE) test $(yamlfile) $(MELANGE_TEST_OPTS) $(MELANGE_DEBUG_TEST_OPTS) --source-dir=./$(*)/

.PHONY: dev-container
dev-container:
	docker run $(DOCKER_PLATFORM_ARG) --pull=always --privileged --rm -it \
		--entrypoint="/bin/bash" \
			--volume="$(PWD):$(PWD)" \
			--workdir="$(PWD)" \
			--env=SOURCE_DATE_EPOCH=$(SOURCE_DATE_EPOCH) \
			--env=HTTP_AUTH \
			ghcr.io/wolfi-dev/sdk:latest -il

PACKAGES_CONTAINER_FOLDER ?= /work/packages
# This target spins up a docker container that is helpful for testing local
# changes to the packages. It mounts the local packages folder as a read-only,
# and sets up the necessary keys for you to run `apk add` commands, and then
# test the packages however you see fit.
.PHONY: local-wolfi
local-wolfi: $(KEY)
	mkdir -p "$(PWD)/packages"
	$(eval TMP_REPOS_DIR := $(shell mktemp --tmpdir=$(MELANGE_TMPDIR) -d "$@.XXXXXX"))
	$(eval TMP_REPOS_FILE := $(TMP_REPOS_DIR)/repositories)
	echo "https://packages.wolfi.dev/os" > $(TMP_REPOS_FILE)
	echo "$(PACKAGES_CONTAINER_FOLDER)" >> $(TMP_REPOS_FILE)
ifneq ($(LOCAL_WOLFI_EXTRA_REPO),)
	echo "$(LOCAL_WOLFI_EXTRA_REPO)" >> $(TMP_REPOS_FILE)
endif
	docker run $(DOCKER_PLATFORM_ARG) --pull=always --rm -it \
		--entrypoint="/bin/sh" \
		--mount=type=bind,source="$(PWD)/packages",destination="$(PACKAGES_CONTAINER_FOLDER)",readonly \
		--mount=type=bind,source="$(PWD)/$(KEY).pub",destination="/etc/apk/keys/$(KEY).pub",readonly \
		--mount=type=bind,source="$(TMP_REPOS_FILE)",destination="/etc/apk/repositories",readonly \
		--workdir="$(PACKAGES_CONTAINER_FOLDER)" \
		"cgr.dev/chainguard/wolfi-base:latest" -il
	rm "$(TMP_REPOS_FILE)"
	rmdir "$(TMP_REPOS_DIR)"

# This target spins up a docker container that is helpful for building images
# using local packages.
#
# It mounts the:
#
#  - local packages dir (default: pwd) as a read-only, as /work/packages. This
#    is where the local packages are set up to be fetched from.
#  - local os dir (default: pwd) as a read-only, as /work/os. This is where
#    apko config files should live in. Note that this can be the current
#    directory also.
#
# Both of these can be overridden with PACKAGES_CONTAINER_FOLDER and OS_DIR
# respectively.
#
# It sets up the necessary tools, keys, and repositories for you to run
# apko to build images and then test them. Currently, the apko tool requires a
# few flags to get the image built, but we'll work on getting the viper config
# set up to make this easier.
#
# The resulting image will be in the OUT_DIR, and it is best to specify the
# OUT_DIR as a directory in the host system, so that it will persist after the
# container is done, as well as you can test / iterate with the image and run
# tests in the host.
#
# Example invocation for
#
# mkdir /tmp/out && OUT_DIR=/tmp/out make dev-container-wolfi
#
# Then in the container, you could build an image like this:
#
# apko -C /work/out build --keyring-append /etc/apk/keys/wolfi-signing.rsa.pub \
#  --keyring-append /etc/apk/keys/local-melange.rsa.pub --arch host \
# /work/os/conda-IMAGE.yaml conda-test:test /work/out/conda-test.tar
#
# Then from the host you can run:
#
# docker load -i /tmp/out/conda-test.tar
# docker run -it
.PHONY: dev-container-wolfi
dev-container-wolfi: $(KEY)
	$(eval TMP_REPOS_DIR := $(shell mktemp --tmpdir=$(MELANGE_TMPDIR) -d "$@.XXXXXX"))
	$(eval TMP_REPOS_FILE := $(TMP_REPOS_DIR)/repositories)
	$(eval OUT_LOCAL_DIR ?= /work/out)
	$(eval OUT_DIR ?= $(shell mktemp --tmpdir=$(MELANGE_TMPDIR) -d))
	$(eval OS_LOCAL_DIR ?= /work/os)
	$(eval OS_DIR ?= $(PWD))
	echo "https://packages.wolfi.dev/os" > $(TMP_REPOS_FILE)
	echo "$(PACKAGES_CONTAINER_FOLDER)" >> $(TMP_REPOS_FILE)
ifneq ($(LOCAL_WOLFI_EXTRA_REPO),)
	echo "$(LOCAL_WOLFI_EXTRA_REPO)" >> $(TMP_REPOS_FILE)
endif
	docker run $(DOCKER_PLATFORM_ARG) --pull=always --rm -it \
		--entrypoint="/bin/bash" \
		--mount=type=bind,source="$(OUT_DIR)",destination="$(OUT_LOCAL_DIR)" \
		--mount=type=bind,source="$(OS_DIR)",destination="$(OS_LOCAL_DIR)",readonly \
		--mount=type=bind,source="$(PWD)/packages",destination="$(PACKAGES_CONTAINER_FOLDER)",readonly \
		--mount=type=bind,source="$(PWD)/$(KEY).pub",destination="/etc/apk/keys/$(KEY).pub",readonly \
		--mount=type=bind,source="$(TMP_REPOS_FILE)",destination="/etc/apk/repositories",readonly \
		--workdir="$(PACKAGES_CONTAINER_FOLDER)" \
		"ghcr.io/wolfi-dev/sdk:latest" -il
	rm "$(TMP_REPOS_FILE)"
	rmdir "$(TMP_REPOS_DIR)"

# Checks that the repo can be built in order from bootstrap packages.
.PHONY: check-bootstrap
check-bootstrap:
	$(WOLFICTL) text --dir . --type name --pipeline-dir=./pipelines/ \
		--keyring-append $(BOOTSTRAP_KEY) \
		--repository-append $(BOOTSTRAP_REPO)

authget = tok=$$(chainctl auth token --audience=$(1)) || \
	{ echo "failed token from $(1) for target $@"; exit 1; }; \
	mkdir -p $$(dirname $(2)) && \
	echo "auth-download[$(1)] to $(2) from $(3)" && \
	curl --fail -LS --silent -o $(2).tmp --user "user:$$tok" $(3) && \
	mv "$(2).tmp" "$(2)"
