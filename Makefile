USE_CACHE ?= no
ARCH ?= $(shell uname -m)
ifeq (${ARCH}, arm64)
	ARCH = aarch64
endif
ifeq (${TMPDIR}, )
        CACHEDIR = /tmp/melange-cache
else
        CACHEDIR = ${TMPDIR}/melange-cache
endif
TARGETDIR = packages/${ARCH}

MELANGE ?= $(shell which melange)
WOLFICTL ?= $(shell which wolfictl)
KEY ?= local-melange.rsa
REPO ?= $(shell pwd)/packages
QEMU_KERNEL_REPO := https://apk.cgr.dev/chainguard-private/

ifeq (${MELANGE_RUNNER},)
MELANGE_RUNNER = qemu
$(warning ****************************** WARNING ******************************)
$(warning *** MELANGE_RUNNER is unset. The default runner is now qemu, which)
$(warning *** requires chainctl authentication to access the Chainguard kernel.)
$(warning *** See `melange build --help` for a list of other runner options.)
$(warning ****************************** WARNING ******************************)
endif

MELANGE_OPTS += --runner=${MELANGE_RUNNER}
MELANGE_TEST_OPTS += --runner=${MELANGE_RUNNER}
QEMU_KERNEL_IMAGE ?= kernel/$(ARCH)/vmlinuz
ifeq (${MELANGE_RUNNER},qemu)
	QEMU_KERNEL_DEP = ${QEMU_KERNEL_IMAGE}
	export QEMU_KERNEL_IMAGE
endif

MELANGE_OPTS += --repository-append ${REPO}
MELANGE_OPTS += --keyring-append ${KEY}.pub
MELANGE_OPTS += --signing-key ${KEY}
MELANGE_OPTS += --arch ${ARCH}
MELANGE_OPTS += --env-file build-${ARCH}.env
MELANGE_OPTS += --namespace wolfi
MELANGE_OPTS += --license 'Apache-2.0'
MELANGE_OPTS += --git-repo-url 'https://github.com/wolfi-dev/os'
MELANGE_OPTS += --cache-dir ${CACHEDIR}
MELANGE_OPTS += --pipeline-dir ./pipelines/
MELANGE_OPTS += ${MELANGE_EXTRA_OPTS}

# Enter interactive mode on failure for debug
MELANGE_DEBUG_OPTS += --interactive
MELANGE_DEBUG_OPTS += --debug
MELANGE_DEBUG_OPTS += --package-append apk-tools
MELANGE_DEBUG_OPTS += ${MELANGE_OPTS}

# Enter interactive mode on test failure for debug
MELANGE_DEBUG_TEST_OPTS += --interactive

# These are separate from MELANGE_OPTS because for building we need additional
# ones that are not defined for tests.
MELANGE_TEST_OPTS += --repository-append ${REPO}
MELANGE_TEST_OPTS += --keyring-append ${KEY}.pub
MELANGE_TEST_OPTS += --arch ${ARCH}
MELANGE_TEST_OPTS += --pipeline-dirs ./pipelines/
MELANGE_TEST_OPTS += --repository-append https://packages.wolfi.dev/os
MELANGE_TEST_OPTS += --keyring-append https://packages.wolfi.dev/os/wolfi-signing.rsa.pub
MELANGE_TEST_OPTS += --test-package-append wolfi-base
MELANGE_TEST_OPTS += --debug
MELANGE_TEST_OPTS += ${MELANGE_EXTRA_OPTS}

ifeq (${LINT}, yes)
	MELANGE_OPTS += --fail-on-lint-warning
endif

BOOTSTRAP_REPO ?= https://packages.wolfi.dev/bootstrap/stage3
BOOTSTRAP_KEY ?= https://packages.wolfi.dev/bootstrap/stage3/wolfi-signing.rsa.pub
WOLFI_REPO ?= https://packages.wolfi.dev/os
WOLFI_KEY ?= https://packages.wolfi.dev/os/wolfi-signing.rsa.pub
BOOTSTRAP ?= no

ifeq (${BOOTSTRAP}, yes)
	MELANGE_OPTS += -k ${BOOTSTRAP_KEY}
	MELANGE_OPTS += -r ${BOOTSTRAP_REPO}
else
	MELANGE_OPTS += -k ${WOLFI_KEY}
	MELANGE_OPTS += -r ${WOLFI_REPO}
endif

# Evaluate all package manifests and packages
yamls := $(wildcard *.yaml)
pkgs := $(subst .yaml,,$(yamls))

${KEY}:
	${MELANGE} keygen ${KEY}

.PHONY: cache
cache:
	mkdir -p ${CACHEDIR}

.PHONY: clean
clean:
	rm -rf packages/${ARCH}
	rm -rf kernel/

.PHONY: clean-cache
clean-cache:
	rm -rf ${CACHEDIR}

%/.guarded-repo.token:
	$(eval pkgname := $*)
	tmpf=$(shell mktemp) && \
	chainctl auth octo-sts --identity=guarded-package-repos --scope=chainguard-dev > $${tmpf} && \
	mkdir -p $(pkgname) && \
	mv $${tmpf} ./$(pkgname)/.guarded-repo.token

repo_token_targets = $(foreach name,$(pkgs),repo-token/$(name))
$(repo_token_targets): repo-token/%: %/.guarded-repo.token

%/.libraries.token:
	$(eval pkgname := $*)
	tmpf=$(shell mktemp) && \
	chainctl auth token --audience libraries.cgr.dev > $${tmpf} && \
	mkdir -p $(pkgname) && \
	mv $${tmpf} ./$(pkgname)/.libraries.token

libraries_token_targets = $(foreach name,$(pkgs),lib-token/$(name))
$(libraries_token_targets): lib-token/%: %/.libraries.token

.PHONY: tokens-if-needed/%
tokens-if-needed/%:
	$(eval pkgname := $*)
	$(MAKE) compile/$(pkgname)
	$(call repo_token_if_needed,$(pkgname))
	$(call libraries_token_if_needed,$(pkgname))

.PHONY: clean-tokens/%
clean-tokens/%:
	$(eval pkgname := $*)
	rm -rf ./$(pkgname)/.*.token

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
	# Extract lines with 'P:linux-qemu-generic' and the following line that contains the version
	# This approach is compatible with both GNU and BSD sed
	awk '/^P:linux-qemu-generic$$/ {print; getline; print}' $< > kernel/$*/available
	grep '^V:' kernel/$*/available | sed 's/V://' | \
	  sort -V | tail -n1 > $@.tmp
	# Sanity check that this looks like an apk version
	grep -E '^([0-9]+\.)+[0-9]+-r[0-9]+$$' $@.tmp
	mv $@.tmp $@

kernel/%/linux.apk: kernel/%/chosen
	@$(call authget,apk.cgr.dev,$@,$(QEMU_KERNEL_REPO)/$*/linux-qemu-generic-$(shell cat kernel/$*/chosen).apk)

kernel/%/vmlinuz: kernel/%/linux.apk
	tmpd=kernel/.$$$$ && mkdir -p $$tmpd $(dir $@) && \
		tar -x -C $$tmpd -f $< boot/ 2> /dev/null && \
		[ -f $$tmpd/boot/vmlinuz ] && mv $$tmpd/boot/* $(dir $@) && \
		rc=$$?; rm -Rf $$tmpd; exit $$rc
	touch $@

pkg_targets = $(foreach name,$(pkgs),package/$(name))
$(pkg_targets): package/%:
	$(eval yamlfile := $*.yaml)
	$(eval pkgver := $(shell $(MELANGE) package-version $(yamlfile)))
	@printf "Building package $* with version $(pkgver) from file $(yamlfile)\n"
	$(MAKE) yamlfile=$(yamlfile) pkgname=$* packages/$(ARCH)/$(pkgver).apk

packages/$(ARCH)/%.apk: cache $(KEY) $(QEMU_KERNEL_DEP)
	$(MAKE) tokens-if-needed/$(pkgname)
	mkdir -p ./$(pkgname)/
	$(eval SOURCE_DATE_EPOCH ?= $(shell git log -1 --pretty=%ct --follow $(yamlfile)))
	$(info @SOURCE_DATE_EPOCH=$(SOURCE_DATE_EPOCH) $(MELANGE) build $(yamlfile) $(MELANGE_OPTS) --source-dir ./$(pkgname)/)
	bash -xc "trap 'trap - SIGINT SIGTERM ERR; $(MAKE) clean-tokens/$(pkgname); exit 1' SIGINT SIGTERM ERR; SOURCE_DATE_EPOCH=$(SOURCE_DATE_EPOCH) $(MELANGE) build $(yamlfile) $(MELANGE_OPTS) --source-dir ./$(pkgname)/"
	$(MAKE) clean-tokens/$(pkgname)

docker_pkg_targets = $(foreach name,$(pkgs),docker-package/$(name))
$(docker_pkg_targets): docker-package/%:
	@echo "Building using docker runner"
	MELANGE_RUNNER=docker make package/$*

dbg_targets = $(foreach name,$(pkgs),debug/$(name))
$(dbg_targets): debug/%: cache $(KEY) $(QEMU_KERNEL_DEP)
	$(eval yamlfile := $*.yaml)
	$(eval pkgname := $*)
	$(eval pkgver := $(shell $(MELANGE) package-version $(yamlfile)))
	$(MAKE) tokens-if-needed/$(pkgname)
	@printf "Building package $* with version $(pkgver) from file $(yamlfile)\n"
	mkdir -p ./"$*"/
	$(eval SOURCE_DATE_EPOCH ?= $(shell git log -1 --pretty=%ct --follow $(yamlfile)))
	$(info @SOURCE_DATE_EPOCH=$(SOURCE_DATE_EPOCH) $(MELANGE) build $(yamlfile) $(MELANGE_DEBUG_OPTS) --source-dir ./$(*)/)
	bash -xc "trap 'trap - SIGINT SIGTERM ERR; $(MAKE) clean-tokens/$(pkgname); exit 1' SIGINT SIGTERM ERR; SOURCE_DATE_EPOCH=$(SOURCE_DATE_EPOCH) $(MELANGE) build $(yamlfile) $(MELANGE_DEBUG_OPTS) --source-dir ./$(*)/"
	$(MAKE) clean-tokens/$(pkgname)

test_targets = $(foreach name,$(pkgs),test/$(name))
$(test_targets): test/%: cache $(KEY) $(QEMU_KERNEL_DEP)
	mkdir -p ./$(*)/
	$(eval yamlfile := $*.yaml)
	$(eval pkgname := $*)
	$(eval pkgver := $(shell $(MELANGE) package-version $(yamlfile)))
	$(MAKE) tokens-if-needed/$(pkgname)
	@printf "Testing package $* with version $(pkgver) from file $(yamlfile)\n"
	bash -xc "trap 'trap - SIGINT SIGTERM ERR; $(MAKE) clean-tokens/$(pkgname); exit 1' SIGINT SIGTERM ERR; $(MELANGE) test $(yamlfile) $(MELANGE_TEST_OPTS) --source-dir ./$(*)/"
	$(MAKE) clean-tokens/$(pkgname)

docker_test_targets = $(foreach name,$(pkgs),docker-test/$(name))
$(docker_test_targets): docker-test/%:
	@echo "Testing using docker runner"
	MELANGE_RUNNER=docker make test/$*

testdbg_targets = $(foreach name,$(pkgs),test-debug/$(name))
$(testdbg_targets): test-debug/%: cache $(KEY) $(QEMU_KERNEL_DEP)
	mkdir -p ./$(*)/
	$(eval yamlfile := $*.yaml)
	$(eval pkgname := $*)
	$(eval pkgver := $(shell $(MELANGE) package-version $(yamlfile)))
	$(MAKE) tokens-if-needed/$(pkgname)
	@printf "Testing package $* with version $(pkgver) from file $(yamlfile)\n"
	bash -xc "trap 'trap - SIGINT SIGTERM ERR; $(MAKE) clean-tokens/$(pkgname); exit 1' SIGINT SIGTERM ERR; $(MELANGE) test $(yamlfile) $(MELANGE_TEST_OPTS) $(MELANGE_DEBUG_TEST_OPTS) --source-dir ./$(*)/"
	$(MAKE) clean-tokens/$(pkgname)

compile_targets = $(foreach name,$(pkgs),compile/$(name))
$(compile_targets): compile/%:
	mkdir -p ./compiled ./$(*)/
	$(eval jsonfile := compiled/$*.json)
	$(eval yamlfile := $*.yaml)
	$(eval pkgname := $*)
	$(MELANGE) compile $(yamlfile) $(MELANGE_OPTS) --source-dir ./$(*)/ > $(jsonfile)
	@printf "Compiled manifest for $(pkgname) written to $(jsonfile)"

.PHONY: dev-container
dev-container:
	docker run --pull=always --privileged --rm -it \
	    -v "${PWD}:${PWD}" \
	    -v "${CACHEDIR}:/tmp/melange-cache" \
	    -w "${PWD}" \
	    -e SOURCE_DATE_EPOCH=0 \
	    -e HTTP_AUTH \
	    ghcr.io/wolfi-dev/sdk:latest

PACKAGES_CONTAINER_FOLDER ?= /work/packages
# This target spins up a docker container that is helpful for testing local
# changes to the packages. It mounts the local packages folder as a read-only,
# and sets up the necessary keys for you to run `apk add` commands, and then
# test the packages however you see fit.
.PHONY: local-wolfi
local-wolfi: $(KEY)
	mkdir -p "${PWD}/packages"
	$(eval TMP_REPOS_DIR := $(shell mktemp --tmpdir -d "$@.XXXXXX"))
	$(eval TMP_REPOS_FILE := $(TMP_REPOS_DIR)/repositories)
	echo "https://packages.wolfi.dev/os" > $(TMP_REPOS_FILE)
	echo "$(PACKAGES_CONTAINER_FOLDER)" >> $(TMP_REPOS_FILE)
	docker run --pull=always --rm -it \
		--mount type=bind,source="${PWD}/packages",destination="$(PACKAGES_CONTAINER_FOLDER)",readonly \
		--mount type=bind,source="${PWD}/$(KEY).pub",destination="/etc/apk/keys/$(KEY).pub",readonly \
		--mount type=bind,source="$(TMP_REPOS_FILE)",destination="/etc/apk/repositories",readonly \
		-w "$(PACKAGES_CONTAINER_FOLDER)" \
		cgr.dev/chainguard/wolfi-base:latest
	rm "$(TMP_REPOS_FILE)"
	rmdir "$(TMP_REPOS_DIR)"

# This target spins up a docker container that is helpful for building images
# using local packages.
# It mounts the:
#  - local packages dir (default: pwd) as a read-only, as /work/packages. This
#    is where the local packages are set up to be fetched from.
#  - local os dir (default: pwd) as a read-only, as /work/os. This is where
#    apko config files should live in. Note that this can be the current
#    directory also.
# Both of these can be overridden with PACKAGES_CONTAINER_FOLDER and OS_DIR
# respectively.
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
# mkdir /tmp/out && OUT_DIR=/tmp/out make dev-container-wolfi
# Then in the container, you could build an image like this:
# apko -C /work/out build --keyring-append /etc/apk/keys/wolfi-signing.rsa.pub \
#  --keyring-append /etc/apk/keys/local-melange.rsa.pub --arch host \
# /work/os/conda-IMAGE.yaml conda-test:test /work/out/conda-test.tar
#
# Then from the host you can run:
# docker load -i /tmp/out/conda-test.tar
# docker run -it
OUT_LOCAL_DIR ?= /work/out
OS_LOCAL_DIR ?= /work/os
OS_DIR ?= ${PWD}

.PHONY: dev-container-wolfi
dev-container-wolfi: $(KEY)
	$(eval TMP_REPOS_DIR := $(shell mktemp --tmpdir -d "$@.XXXXXX"))
	$(eval TMP_REPOS_FILE := $(TMP_REPOS_DIR)/repositories)
	$(eval OUT_DIR := $(shell echo $${OUT_DIR:-$$(mktemp --tmpdir -d "$@-out.XXXXXX")}))
	echo "https://packages.wolfi.dev/os" > $(TMP_REPOS_FILE)
	echo "$(PACKAGES_CONTAINER_FOLDER)" >> $(TMP_REPOS_FILE)
	docker run --pull=always --rm -it \
		--mount type=bind,source="${OUT_DIR}",destination="$(OUT_LOCAL_DIR)" \
		--mount type=bind,source="${OS_DIR}",destination="$(OS_LOCAL_DIR)",readonly \
		--mount type=bind,source="${PWD}/packages",destination="$(PACKAGES_CONTAINER_FOLDER)",readonly \
		--mount type=bind,source="${PWD}/$(KEY).pub",destination="/etc/apk/keys/$(KEY).pub",readonly \
		--mount type=bind,source="$(TMP_REPOS_FILE)",destination="/etc/apk/repositories",readonly \
		-w "$(PACKAGES_CONTAINER_FOLDER)" \
		ghcr.io/wolfi-dev/sdk:latest
	rm "$(TMP_REPOS_FILE)"
	rmdir "$(TMP_REPOS_DIR)"

# Checks that the repo can be built in order from bootstrap packages.
.PHONY: check-bootstrap
check-bootstrap:
	$(WOLFICTL) text --dir . --type name --pipeline-dir=./pipelines/ \
		-k ${BOOTSTRAP_KEY} \
		-r ${BOOTSTRAP_REPO}

define authget
tok=$$(chainctl auth token --audience=$(1)) || \
{ echo "failed token from $(1) for target $@"; exit 1; }; \
mkdir -p $$(dirname $(2)) && \
echo "auth-download[$(1)] to $(2) from $(3)" && \
curl --fail -LS --silent -o $(2).tmp --user "user:$$tok" $(3) && \
mv "$(2).tmp" "$(2)"
endef

define repo_token_if_needed
$(eval jsonfile := compiled/$1.json)
$(eval pkgname := $1)

@if jq -er '.. | .uses? | strings | select(test("auth/guarded-repo"))' $(jsonfile); then \
	echo "Creating guarded repo token for $(pkgname)…"; \
	$(MAKE) repo-token/$(pkgname); \
else \
	echo "$(pkgname) does not use a guarded repo. Skipping token creation."; \
fi
endef

define libraries_token_if_needed
$(eval jsonfile := compiled/$1.json)
$(eval pkgname := $1)

@if jq -er '.. | .uses? | strings | select(test("auth/(?!guarded-repo)"))' $(jsonfile); then \
	echo "Creating guarded libraries token for $(pkgname)…"; \
	$(MAKE) lib-token/$(pkgname); \
else \
	echo "$(pkgname) does not use guarded libraries. Skipping token creation."; \
fi
endef
