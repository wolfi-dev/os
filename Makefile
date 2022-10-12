ARCH := $(shell uname -m)
MELANGE_DIR ?= ../melange
MELANGE ?= ${MELANGE_DIR}/melange
KEY ?= local-melange.rsa
REPO ?= $(shell pwd)/packages

MELANGE_OPTS += --repository-append ${REPO}
MELANGE_OPTS += --keyring-append ${KEY}.pub
MELANGE_OPTS += --signing-key ${KEY}
MELANGE_OPTS += --pipeline-dir ${MELANGE_DIR}/pipelines
MELANGE_OPTS += --arch ${ARCH}
MELANGE_OPTS += ${MELANGE_EXTRA_OPTS}

define build-package

packages/${ARCH}/$(1)-$(2).apk: ${KEY}
	mkdir -p ./$(1)/
	${MELANGE} build $(1).yaml ${MELANGE_OPTS} --source-dir ./$(1)/

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
$(eval $(call build-package,gmp,6.2.1-r4))
$(eval $(call build-package,mpfr,4.1.0-r3))
$(eval $(call build-package,mpc,1.2.1-r2))
$(eval $(call build-package,isl,0.24-r2))
$(eval $(call build-package,zlib,1.2.12-r3))
$(eval $(call build-package,flex,2.6.4-r1))
$(eval $(call build-package,glibc,2.36-r1))
$(eval $(call build-package,build-base,1-r3))
$(eval $(call build-package,gcc,12.2.0-r6))
$(eval $(call build-package,openssl,3.0.5-r3))
$(eval $(call build-package,binutils,2.39-r3))
$(eval $(call build-package,bison,3.8.2-r1))
$(eval $(call build-package,pax-utils,1.3.4-r2))
$(eval $(call build-package,texinfo,6.8-r0))
$(eval $(call build-package,gzip,1.12-r1))
$(eval $(call build-package,busybox,1.35.0-r3))
$(eval $(call build-package,make,4.3-r1))
$(eval $(call build-package,sed,4.8-r1))
$(eval $(call build-package,mpdecimal,2.5.1-r1))
$(eval $(call build-package,libffi,3.4.2-r1))
$(eval $(call build-package,linux-headers,5.16.9-r2))
$(eval $(call build-package,gdbm,1.23-r1))
$(eval $(call build-package,grep,3.7-r2))
$(eval $(call build-package,gawk,5.1.1-r3))
$(eval $(call build-package,file,5.42-r3))
$(eval $(call build-package,expat,2.4.9-r0))
$(eval $(call build-package,m4,1.4.19-r2))
$(eval $(call build-package,bzip2,1.0.8-r2))
$(eval $(call build-package,perl,5.36.0-r1))
$(eval $(call build-package,ca-certificates,20220614-r2))
$(eval $(call build-package,autoconf,2.71-r0))
$(eval $(call build-package,automake,1.16.5-r0))
$(eval $(call build-package,help2man,1.49.2-r0))
$(eval $(call build-package,libtool,2.4.7-r0))
$(eval $(call build-package,patch,2.7.6-r3))
$(eval $(call build-package,ncurses,6.3-r2))
$(eval $(call build-package,pkgconf,1.9.3-r3))
$(eval $(call build-package,readline,8.1.2-r1))
$(eval $(call build-package,sqlite,3.39.2-r1))
$(eval $(call build-package,xz,5.2.6-r2))
$(eval $(call build-package,python3,3.10.7-r0))
$(eval $(call build-package,scdoc,1.11.2-r1))
$(eval $(call build-package,linenoise,1.0-r0))
$(eval $(call build-package,lua5.3,5.3.6-r2))
$(eval $(call build-package,lua5.3-lzlib,0.4.3-r0))
$(eval $(call build-package,apk-tools,2.12.9-r3))
$(eval $(call build-package,wget,1.21.3-r2))
$(eval $(call build-package,wolfi-keys,1-r1))
$(eval $(call build-package,wolfi-baselayout,20220914-r0))
$(eval $(call build-package,wolfi-base,1-r1))
$(eval $(call build-package,oniguruma,6.9.8-r0))
$(eval $(call build-package,jq,1.6-r0))
$(eval $(call build-package,brotli,1.0.9-r0))
$(eval $(call build-package,libev,4.33-r0))
$(eval $(call build-package,c-ares,1.18.1-r0))
$(eval $(call build-package,nghttp2,1.49.0-r0))
$(eval $(call build-package,curl,7.85.0-r1))
$(eval $(call build-package,attr,2.5.1-r0))
$(eval $(call build-package,acl,2.3.1-r0))
$(eval $(call build-package,coreutils,9.1-r0))
$(eval $(call build-package,diffutils,3.8-r0))
$(eval $(call build-package,findutils,4.9.0-r0))
$(eval $(call build-package,procps,4.0.0-r0))
$(eval $(call build-package,samurai,1.2-r0))
$(eval $(call build-package,lz4,1.9.4-r0))
$(eval $(call build-package,zstd,1.5.2-r0))
$(eval $(call build-package,libarchive,3.6.1-r1))
$(eval $(call build-package,libuv,1.44.2-r1))
$(eval $(call build-package,rhash,1.4.3-r1))
$(eval $(call build-package,cmake,3.24.2-r0))
$(eval $(call build-package,py3-appdirs,1.4.4-r0))
$(eval $(call build-package,py3-ordered-set,4.0.2-r0))
$(eval $(call build-package,py3-installer,0.5.1-r0))
$(eval $(call build-package,py3-tomli,2.0.1-r0))
$(eval $(call build-package,py3-gpep517,9-r1))
$(eval $(call build-package,py3-flit-core,3.7.1-r0))
$(eval $(call build-package,py3-parsing,3.0.9-r0))
$(eval $(call build-package,py3-packaging,21.3-r0))
$(eval $(call build-package,py3-more-itertools,8.13.0-r0))
$(eval $(call build-package,py3-setuptools-stage0,52.0.0-r0))
$(eval $(call build-package,py3-setuptools,59.4.0-r0))
$(eval $(call build-package,py3-pep517,0.13.0-r0))
$(eval $(call build-package,py3-six,1.16.0-r0))
$(eval $(call build-package,py3-retrying,1.3.3-r0))
$(eval $(call build-package,py3-contextlib2,21.6.0-r0))
$(eval $(call build-package,py3-pip,22.2.2-r0))
$(eval $(call build-package,libedit,3.1-r0))
$(eval $(call build-package,pcre2,10.40-r0))
$(eval $(call build-package,git,2.37.3-r0))
$(eval $(call build-package,bash,5.2_rc4-r0))
$(eval $(call build-package,go-stage0,1.19.1-r0))
$(eval $(call build-package,go,1.19.1-r0))
$(eval $(call build-package,git-lfs,3.1.4-r0))
$(eval $(call build-package,openssh,9.0_p1-r0))
$(eval $(call build-package,skalibs,2.12.0.0-r0))
$(eval $(call build-package,execline,2.9.0.1-r0))
$(eval $(call build-package,s6,2.11.1.2-r0))
$(eval $(call build-package,libretls,3.5.2-r0))
$(eval $(call build-package,grype,0.50.2-r0))
$(eval $(call build-package,trivy,0.32.0-r0))
$(eval $(call build-package,ruby,3.1.2-r0))
$(eval $(call build-package,rust-stage0,1.64.0-r0))
$(eval $(call build-package,meson,0.63.3-r0))

.build-packages: ${PACKAGES}
