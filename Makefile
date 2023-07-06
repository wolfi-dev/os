USE_CACHE ?= yes
ARCH ?= $(shell uname -m)
ifeq (${ARCH}, arm64)
	ARCH = aarch64
endif
TARGETDIR = packages/${ARCH}

MELANGE ?= $(shell which melange)
WOLFICTL ?= $(shell which wolfictl)
KEY ?= local-melange.rsa
REPO ?= $(shell pwd)/packages
CACHE_DIR ?= gs://wolfi-sources/

WOLFI_SIGNING_PUBKEY ?= https://packages.wolfi.dev/os/wolfi-signing.rsa.pub
WOLFI_PROD ?= https://packages.wolfi.dev/os

MELANGE_OPTS += --repository-append ${REPO}
MELANGE_OPTS += --keyring-append ${KEY}.pub
MELANGE_OPTS += --signing-key ${KEY}
MELANGE_OPTS += --arch ${ARCH}
MELANGE_OPTS += --env-file build-${ARCH}.env
MELANGE_OPTS += --namespace wolfi
MELANGE_OPTS += --generate-index false
MELANGE_OPTS += ${MELANGE_EXTRA_OPTS}

ifeq (${USE_CACHE}, yes)
	MELANGE_OPTS += --cache-source ${CACHE_DIR}
endif

ifeq (${BUILDWORLD}, no)
MELANGE_OPTS += -k ${WOLFI_SIGNING_PUBKEY}
MELANGE_OPTS += -r ${WOLFI_PROD}
endif

# The list of packages to be built. The order matters.
# wolfictl determines the list and order
PKG_FULL_LIST ?= $(shell $(WOLFICTL) text --dir . --type name-version)

all: ${KEY} .build-packages

${KEY}:
	${MELANGE} keygen ${KEY}

clean:
	rm -rf packages/${ARCH}

.PHONY: list list-yaml
list:
	$(eval PKGLIST ?= $(shell $(WOLFICTL) text --dir . --type name))
	$(info $(PKGLIST))
	@printf ''

list-yaml:
	$(eval PKGLIST ?= $(shell $(WOLFICTL) text --dir . --type name))
	$(info $(addsuffix .yaml,$(PKGLIST)))
	@printf ''

.build-packages: $(addsuffix .apk,$(addprefix packages/$(ARCH)/,${PKG_FULL_LIST}))

package/%:
	$(eval yamlfile := $*.yaml)
	$(eval pkgver := $(shell $(MELANGE) package-version $(yamlfile)))
	$(MAKE) packages/$(ARCH)/$(pkgver).apk

packages/$(ARCH)/%.apk: $(KEY)
	$(eval pkgname := $(word 1, $(subst -, , $*)))
	$(eval yamlfile := $(pkgname).yaml)
	@mkdir -p ./$(pkgname)/
	$(eval SOURCE_DATE_EPOCH ?= $(shell git log -1 --pretty=%ct --follow $(yamlfile)))
	@SOURCE_DATE_EPOCH=$(SOURCE_DATE_EPOCH) $(MELANGE) build $(yamlfile) $(MELANGE_OPTS) --source-dir ./$(pkgname)/ --log-policy builtin:stderr,$(TARGETDIR)/buildlogs/$*.log

dev-container:
	docker run --privileged --rm -it -v "${PWD}:${PWD}" -w "${PWD}" ghcr.io/wolfi-dev/sdk:latest@sha256:3ba6e392eff7f09493c62b8a6bff4b9378ecccc27e5dc4ba0fa9f2a0e95c666f
