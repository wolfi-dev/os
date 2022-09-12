ARCH := $(shell uname -m)
MELANGE_DIR ?= ../melange
MELANGE ?= ${MELANGE_DIR}/melange
KEY ?= local-melange.rsa
REPO ?= $(shell pwd)/packages

MELANGE_OPTS ?= \
	--repository-append ${REPO} \
	--keyring-append ${KEY}.pub \
	--signing-key ${KEY} \
	--pipeline-dir ${MELANGE_DIR}/pipelines \
	--arch ${ARCH}

define build-package

packages/${ARCH}/$(1)-$(2).apk: ${KEY}
	${MELANGE} build $(1).yaml ${MELANGE_OPTS} --source-dir ./$(1)/

PACKAGES += packages/${ARCH}/$(1)-$(2).apk

endef

define build-empty-package

packages/${ARCH}/$(1)-$(2).apk: ${KEY}
	${MELANGE} build $(1).yaml ${MELANGE_OPTS} --empty-workspace

PACKAGES += packages/${ARCH}/$(1)-$(2).apk

endef

all: ${KEY} .build-packages

${KEY}:
	${MELANGE} keygen ${KEY}

clean:
	rm -rf packages/${ARCH}

# The list of packages to be built.
#
# Use the `build-package` macro for packages which require a source
# directory, like `glibc/` or `busybox/`.
#
# Use the `build-empty-package` macro for packages which do not require
# a source directory (most of them).
$(eval $(call build-empty-package,gmp,6.2.1-r3))
$(eval $(call build-empty-package,mpfr,4.1.0-r3))
$(eval $(call build-empty-package,mpc,1.2.1-r2))
$(eval $(call build-empty-package,isl,0.24-r2))
$(eval $(call build-empty-package,zlib,1.2.12-r2))
$(eval $(call build-empty-package,flex,2.6.4-r1))
$(eval $(call build-package,glibc,2.36-r0))
$(eval $(call build-empty-package,build-base,1-r3))
$(eval $(call build-empty-package,gcc,12.2.0-r6))
$(eval $(call build-empty-package,openssl,3.0.5-r3))
$(eval $(call build-empty-package,binutils,2.39-r1))
$(eval $(call build-empty-package,bison,3.8.2-r1))
$(eval $(call build-empty-package,pax-utils,1.3.4-r2))
$(eval $(call build-empty-package,texinfo,6.8-r0))
$(eval $(call build-empty-package,gzip,1.12-r1))
$(eval $(call build-package,busybox,1.35.0-r2))
$(eval $(call build-empty-package,make,4.3-r1))
$(eval $(call build-empty-package,sed,4.8-r1))
$(eval $(call build-empty-package,mpdecimal,2.5.1-r1))
$(eval $(call build-empty-package,libffi,3.4.2-r1))
$(eval $(call build-empty-package,linux-headers,5.16.9-r2))
$(eval $(call build-empty-package,gdbm,1.23-r1))
$(eval $(call build-empty-package,grep,3.7-r2))
$(eval $(call build-empty-package,gawk,5.1.1-r3))
$(eval $(call build-empty-package,file,5.42-r3))
$(eval $(call build-empty-package,expat,2.4.8-r2))
$(eval $(call build-empty-package,m4,1.4.19-r2))
$(eval $(call build-package,bzip2,1.0.8-r2))
$(eval $(call build-empty-package,perl,5.36.0-r1))
$(eval $(call build-empty-package,ca-certificates,20220614-r2))
$(eval $(call build-empty-package,patch,2.7.6-r2))
$(eval $(call build-empty-package,ncurses,6.3-r2))
$(eval $(call build-empty-package,pkgconf,1.9.3-r2))
$(eval $(call build-package,readline,8.1.2-r1))
$(eval $(call build-empty-package,sqlite,3.39.2-r1))
$(eval $(call build-empty-package,xz,5.2.6-r2))
$(eval $(call build-empty-package,python3,3.10.7-r0))
$(eval $(call build-empty-package,scdoc,1.11.2-r1))
$(eval $(call build-package,linenoise,1.0-r0))
$(eval $(call build-empty-package,autoconf,2.71-r0))
$(eval $(call build-empty-package,automake,1.16.5-r0))
$(eval $(call build-empty-package,help2man,1.49.2-r0))
$(eval $(call build-package,libtool,2.4.7-r0))

.build-packages: ${PACKAGES}
