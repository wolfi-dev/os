USE_CACHE ?= yes
ARCH ?= $(shell uname -m)
ifeq (${ARCH}, arm64)
	ARCH = aarch64
endif
TARGETDIR = packages/${ARCH}

MELANGE ?= $(shell which melange)
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

define build-package
$(eval pkgname = $(call comma-split,$(1),1))
$(eval sourcedir = $(call comma-split,$(1),2))
$(eval sourcedir = $(or $(sourcedir),$(pkgname)))
$(eval pkgfullname = $(shell $(MELANGE) package-version $(pkgname).yaml))
$(eval pkgtarget = $(TARGETDIR)/$(pkgfullname).apk)
packages/$(pkgname): $(pkgtarget)
$(pkgtarget): ${KEY}
	mkdir -p ./$(sourcedir)/
ifdef SOURCE_DATE_EPOCH
	$(eval CONFIG_DATE_EPOCH := $(SOURCE_DATE_EPOCH))
else
	$(eval CONFIG_DATE_EPOCH := $(shell git log -1 --pretty=%ct --follow $(pkgname).yaml))
endif
	SOURCE_DATE_EPOCH=${CONFIG_DATE_EPOCH} ${MELANGE} build $(pkgname).yaml ${MELANGE_OPTS} --source-dir ./$(sourcedir)/ --log-policy builtin:stderr,${TARGETDIR}/buildlogs/$(pkgfullname).log

endef

# The list of packages to be built. The order matters.
# At some point, when ready, this should be replaced with `wolfictl text -t name .`
# non-standard source directories are provided by adding them separated by a comma,
# e.g.
# postgres-11,postgres
PKGLIST ?= $(shell cat packages.txt | grep -v '^\#' )

all: ${KEY} .build-packages

${KEY}:
	${MELANGE} keygen ${KEY}

clean:
	rm -rf packages/${ARCH}

.PHONY: list list-yaml
list:
	$(info $(PKGNAMELIST))
	@printf ''

list-yaml:
	$(info $(addsuffix .yaml,$(PKGNAMELIST)))
	@printf ''

comma := ,
comma-split = $(word $2,$(subst ${comma}, ,$1))

# PKGLIST includes the optional directory e.g. mariadb-10.6,mariadb
# PKGNAMELIST is only the names
PKGNAMELIST = $(foreach F,$(PKGLIST), $(firstword $(subst ${comma}, ,${F})))

PACKAGES := $(addprefix packages/,$(PKGNAMELIST))

$(foreach pkg,$(PKGLIST),$(eval $(call build-package,$(pkg))))

.build-packages: ${PACKAGES}

dev-container:
	docker run --privileged --rm -it -v "${PWD}:${PWD}" -w "${PWD}" ghcr.io/wolfi-dev/sdk:latest@sha256:3ef78225a85ab45f46faac66603c9da2877489deb643174ba1e42d8cbf0e0644
