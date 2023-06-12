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

ifneq (${BUILDWORLD}, yes)
MELANGE_OPTS += -k ${WOLFI_SIGNING_PUBKEY}
MELANGE_OPTS += -r ${WOLFI_PROD}
endif

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

.packagerules: Makefile .git/HEAD packages.txt
	@echo "Solving build order, please wait..."
	@grep -v '^\#' packages.txt | while read pkg; do		\
		pkgname=`echo $$pkg | cut -d, -f1`;			\
		pkgdir=`echo $$pkg | cut -d, -f2`;			\
		[ -z "$$pkgdir" ] && pkgdir=$$pkgname;			\
		pkgver=`${MELANGE} package-version $${pkgname}.yaml`;	\
		pkgtarget="${TARGETDIR}/$${pkgver}.apk";		\
		echo "PKGNAMELIST += $$pkgname";			\
		echo ".build-packages: $$pkgtarget";			\
		echo "packages/$$pkgname: $$pkgtarget";			\
		echo "$$pkgtarget: $${pkgname}.yaml \$${KEY}";		\
		printf "\t%s\n" "@mkdir -p ./$${pkgdir}/";		\
		printf "\t%s" "SDE=\$${SOURCE_DATE_EPOCH}; [ -z \"\$$\$$SDE\" ] && SDE=\`git log -1 --pretty=%ct --follow $${pkgname}.yaml\`;"; \
		printf "\t%s\n\n" "SOURCE_DATE_EPOCH=\$$\$$SDE \$${MELANGE} build $${pkgname}.yaml \$${MELANGE_OPTS} --source-dir ./$${pkgdir}/ --log-policy builtin:stderr,\$${TARGETDIR}/buildlogs/$${pkgver}.log"; \
	done > .packagerules

-include .packagerules

dev-container:
	docker run --privileged --rm -it -v "${PWD}:${PWD}" -w "${PWD}" ghcr.io/wolfi-dev/sdk:latest@sha256:3ef78225a85ab45f46faac66603c9da2877489deb643174ba1e42d8cbf0e0644
