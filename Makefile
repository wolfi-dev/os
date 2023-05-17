USE_CACHE ?= yes
ARCH ?= $(shell uname -m)
ifeq (${ARCH}, arm64)
	ARCH = aarch64
endif
TARGETDIR = packages/${ARCH}

MELANGE ?= ../melange/melange
KEY ?= local-melange.rsa
REPO ?= $(shell pwd)/packages
SOURCE_DATE_EPOCH ?= 0
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

define build-package
$(eval pkgname = $(1))
$(eval sourcedir = $(pkgname))
$(eval pkgfullname = $(shell $(MELANGE) package-version $(pkgname).yaml))
$(eval pkgtarget = $(TARGETDIR)/$(pkgfullname).apk)
packages/$(pkgname): $(pkgtarget)
$(pkgtarget): ${KEY}
	mkdir -p ./$(sourcedir)/
	SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH} ${MELANGE} build $(pkgname).yaml ${MELANGE_OPTS} --source-dir ./$(sourcedir)/ --log-policy builtin:stderr,${TARGETDIR}/buildlogs/$(pkgfullname).log

endef

# The list of packages to be built. The order matters.
# At some point, when ready, this should be replaced with `wolfictl text -t name .`
PKGLIST ?= $(shell cat packages.txt | grep -v '^\#' )

all: ${KEY} .build-packages

${KEY}:
	${MELANGE} keygen ${KEY}

clean:
	rm -rf packages/${ARCH}

.PHONY: list list-yaml
list:
	$(info $(PKGLIST))
	@printf ''

list-yaml:
	$(info $(addsuffix .yaml,$(PKGLIST)))
	@printf ''

PACKAGES := $(addprefix packages/,$(PKGLIST))

$(foreach pkg,$(PKGLIST),$(eval $(call build-package,$(pkg))))

.build-packages: ${PACKAGES}

dev-container:
	docker run --privileged --rm -it -v "${PWD}:${PWD}" -w "${PWD}" ghcr.io/wolfi-dev/sdk:latest@sha256:515a2c5072753f81ce2cbb81bda54b035aefcdb41d7249070009fc018fecd4c9
