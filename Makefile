ARCH := $(shell uname -m)
MELANGE_DIR ?= ../melange
MELANGE ?= ${MELANGE_DIR}/melange
KEY ?= local-melange.rsa
REPO ?= $(shell pwd)/packages

GLIBC_VERSION ?= 2.36-r0
BUILD_BASE_VERSION ?= 1-r3
OPENSSL_VERSION ?= 3.0.5-r3
BINUTILS_VERSION ?= 2.39-r1
FLEX_VERSION ?= 2.6.4-r0
BISON_VERSION ?= 3.8.2-r1
TEXINFO_VERSION ?= 6.8-r0


MELANGE_OPTS ?= \
	--repository-append ${REPO} \
	--keyring-append ${KEY}.pub \
	--signing-key ${KEY} \
	--pipeline-dir ${MELANGE_DIR}/pipelines \
	--arch ${ARCH}

MELANGE_DEFOPTS ?= --empty-workspace

PACKAGES = \
	packages/${ARCH}/glibc-${GLIBC_VERSION}.apk \
	packages/${ARCH}/build-base-${BUILD_BASE_VERSION}.apk \
	packages/${ARCH}/openssl-${OPENSSL_VERSION}.apk
	packages/${ARCH}/binutils-${BINUTILS_VERSION}.apk \
	packages/${ARCH}/flex-${FLEX_VERSION}.apk \
	packages/${ARCH}/bison-${BISON_VERSION}.apk \
	packages/${ARCH}/texinfo-${TEXINFO_VERSION}.apk \

all: ${KEY} ${PACKAGES}

packages/${ARCH}/glibc-${GLIBC_VERSION}.apk:
	${MELANGE} build glibc.yaml ${MELANGE_OPTS} --source-dir ./glibc/
	apk index -o packages/${ARCH}/APKINDEX.tar.gz packages/${ARCH}/*.apk --allow-untrusted
	melange sign-index --signing-key ${KEY} packages/${ARCH}/APKINDEX.tar.gz

packages/${ARCH}/build-base-${BUILD_BASE_VERSION}.apk:
	${MELANGE} build build-base.yaml ${MELANGE_OPTS} ${MELANGE_DEFOPTS}
	apk index -o packages/${ARCH}/APKINDEX.tar.gz packages/${ARCH}/*.apk --allow-untrusted
	melange sign-index --signing-key ${KEY} packages/${ARCH}/APKINDEX.tar.gz

packages/${ARCH}/openssl-${OPENSSL_VERSION}.apk:
	${MELANGE} build openssl.yaml ${MELANGE_OPTS} ${MELANGE_DEFOPTS}
	apk index -o packages/${ARCH}/APKINDEX.tar.gz packages/${ARCH}/*.apk --allow-untrusted
	melange sign-index --signing-key ${KEY} packages/${ARCH}/APKINDEX.tar.gz
	
packages/${ARCH}/binutils-${BINUTILS_VERSION}.apk:
	${MELANGE} build binutils.yaml ${MELANGE_OPTS} ${MELANGE_DEFOPTS}
	apk index -o packages/${ARCH}/APKINDEX.tar.gz packages/${ARCH}/*.apk --allow-untrusted
	melange sign-index --signing-key ${KEY} packages/${ARCH}/APKINDEX.tar.gz

packages/${ARCH}/flex-${FLEX_VERSION}.apk:
	${MELANGE} build flex.yaml ${MELANGE_OPTS} ${MELANGE_DEFOPTS}
	apk index -o packages/${ARCH}/APKINDEX.tar.gz packages/${ARCH}/*.apk --allow-untrusted
	melange sign-index --signing-key ${KEY} packages/${ARCH}/APKINDEX.tar.gz

packages/${ARCH}/bison-${BISON_VERSION}.apk:
	${MELANGE} build bison.yaml ${MELANGE_OPTS} ${MELANGE_DEFOPTS}
	apk index -o packages/${ARCH}/APKINDEX.tar.gz packages/${ARCH}/*.apk --allow-untrusted
	melange sign-index --signing-key ${KEY} packages/${ARCH}/APKINDEX.tar.gz

packages/${ARCH}/texinfo-${TEXINFO_VERSION}.apk:
	${MELANGE} build texinfo.yaml ${MELANGE_OPTS} ${MELANGE_DEFOPTS}
	apk index -o packages/${ARCH}/APKINDEX.tar.gz packages/${ARCH}/*.apk --allow-untrusted
	melange sign-index --signing-key ${KEY} packages/${ARCH}/APKINDEX.tar.gz

${KEY}:
	${MELANGE} keygen ${KEY}

clean:
	rm -rf packages/${ARCH}
