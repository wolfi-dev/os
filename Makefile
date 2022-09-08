ARCH := $(shell uname -m)
MELANGE_DIR ?= ../melange
MELANGE ?= ${MELANGE_DIR}/melange
KEY ?= local-melange.rsa
REPO ?= $(shell pwd)/packages

GLIBC_VERSION ?= 2.36-r0

MELANGE_OPTS ?= \
	--repository-append ${REPO} \
	--keyring-append ${KEY}.pub \
	--signing-key ${KEY} \
	--pipeline-dir ${MELANGE_DIR}/pipelines \
	--arch ${ARCH}

MELANGE_DEFOPTS ?= --empty-workspace

PACKAGES = \
	packages/${ARCH}/glibc-${GLIBC_VERSION}.apk \

all: ${KEY} ${PACKAGES}

packages/${ARCH}/glibc-${GLIBC_VERSION}.apk:
	${MELANGE} build glibc.yaml ${MELANGE_OPTS} --source-dir ./glibc/
	apk index -o packages/${ARCH}/APKINDEX.tar.gz packages/${ARCH}/*.apk --allow-untrusted
	melange sign-index --signing-key ${KEY} packages/${ARCH}/APKINDEX.tar.gz

${KEY}:
	${MELANGE} keygen ${KEY}

clean:
	rm -rf packages/${ARCH}
