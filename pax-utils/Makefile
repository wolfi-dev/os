# Copyright 2003-2006 Ned Ludd <solar@linbsd.net>
# Distributed under the terms of the GNU General Public License v2
####################################################################

check_compiler = \
	$(shell if $(CC) $(WUNKNOWN) $(1) -S -o /dev/null -xc /dev/null >/dev/null 2>&1; \
	then echo "$(1)"; else echo "$(2)"; fi)
check_compiler_many = $(foreach flag,$(1),$(call check_compiler,$(flag)))

####################################################################
# Avoid CC overhead when installing
ifneq ($(MAKECMDGOALS),install)
WUNKNOWN  := $(call check_compiler,-Werror=unknown-warning-option)
_WFLAGS   := \
	-Wdeclaration-after-statement \
	-Wextra \
	-Wsequence-point \
	-Wstrict-overflow \
	-Wmisleading-indentation
WFLAGS    := -Wall -Wunused -Wimplicit -Wshadow -Wformat=2 \
             -Wmissing-declarations -Wmissing-prototypes -Wwrite-strings \
             -Wbad-function-cast -Wnested-externs -Wcomment -Winline \
             -Wchar-subscripts -Wcast-align -Wno-format-nonliteral \
             $(call check_compiler_many,$(_WFLAGS))
endif

CFLAGS    ?= -O2 -pipe
override CPPFLAGS  += -D_GNU_SOURCE -D_FILE_OFFSET_BITS=64
LDFLAGS   +=
LIBS      :=
DESTDIR    =
PREFIX     = $(DESTDIR)/usr
DATADIR    = $(PREFIX)/share
MANDIR     = $(DATADIR)/man
DOCDIR     = $(DATADIR)/doc
PKGDOCDIR  = $(DOCDIR)/pax-utils
STRIP     := strip
MKDIR     := mkdir -p
INS_EXE   := install -m755
INS_DATA  := install -m644

PKG_CONFIG ?= pkg-config

ifeq ($(USE_CAP),yes)
LIBCAPS_CFLAGS := $(shell $(PKG_CONFIG) --cflags libcap)
LIBCAPS_LIBS   := $(shell $(PKG_CONFIG) --libs libcap)
CPPFLAGS-pspax.c += $(LIBCAPS_CFLAGS) -DWANT_SYSCAP
LIBS-pspax       += $(LIBCAPS_LIBS)
endif

ifeq ($(USE_DEBUG),yes)
override CPPFLAGS += -DEBUG
endif

ifeq ($(BUILD_USE_SECCOMP),yes)
LIBSECCOMP_CFLAGS := $(shell $(PKG_CONFIG) --cflags libseccomp)
LIBSECCOMP_LIBS   := $(shell $(PKG_CONFIG) --libs libseccomp)
override CPPFLAGS += $(LIBSECCOMP_CFLAGS) -DWANT_SECCOMP
LIBS-seccomp-bpf  += $(LIBSECCOMP_LIBS)
endif
ifeq ($(USE_SECCOMP),yes)
override CPPFLAGS += -DWANT_SECCOMP
endif

ifdef PV
override CPPFLAGS  += -DVERSION=\"$(PV)\"
else
VCSID     := $(shell git describe --tags HEAD)
endif
override CPPFLAGS  += -DVCSID='"$(VCSID)"'

####################################################################
ELF_TARGETS  = scanelf dumpelf $(shell $(CC) -dM -E - </dev/null | grep -q __svr4__ || echo pspax)
ELF_OBJS     = paxelf.o paxldso.o
MACH_TARGETS = scanmacho
MACH_OBJS    = paxmacho.o
COMMON_OBJS  = paxinc.o security.o xfuncs.o
BUILD_OBJS   = $(filter-out security.o,$(COMMON_OBJS))
TARGETS      = $(ELF_TARGETS) $(MACH_TARGETS)
TARGETS_OBJS = $(TARGETS:%=%.o)
BUILD_TARGETS= seccomp-bpf
SCRIPTS_SH   = lddtree symtree
SCRIPTS_PY   = lddtree
_OBJS        = $(ELF_OBJS) $(MACH_OBJS) $(COMMON_OBJS)
OBJS         = $(_OBJS) $(TARGETS_OBJS)
# Not all objects support this hack.  Otherwise we'd use $(_OBJS:%.o=%)
OBJS_TARGETS = paxldso
MPAGES       = $(TARGETS:%=man/%.1)
SOURCES      = $(OBJS:%.o=%.c)

all: $(TARGETS)
	@:

all-dev: all $(OBJS_TARGETS)
	@:

DEBUG_FLAGS = \
	-nopie \
	-fsanitize=address \
	-fsanitize=leak \
	-fsanitize=undefined
debug: clean
	$(MAKE) CFLAGS="$(CFLAGS) -g3 -ggdb $(call check_compiler_many,$(DEBUG_FLAGS))" all-dev
	@-chpax  -permsx $(ELF_TARGETS)
	@-paxctl -permsx $(ELF_TARGETS)

analyze: clean
	scan-build $(MAKE) all

fuzz:
	@echo "Pick a fuzzer backend:"
	@echo "$$ make afl-fuzz"
	@echo "$$ make libfuzzer"
	@false

afl-fuzz: clean
	$(MAKE) AFL_HARDEN=1 CC=afl-gcc all
	@rm -rf findings
	@printf '\nNow run:\n%s\n' \
		"afl-fuzz -t 100 -i tests/fuzz/small/ -o findings/ ./scanelf -s '*' -axetrnibSDIYZB @@"

# Not all objects support libfuzzer.
LIBFUZZER_TARGETS = dumpelf
LIBFUZZER_FLAGS = \
	-fsanitize=fuzzer \
	-fsanitize-coverage=edge
libfuzzer: clean
	$(MAKE) \
		CC="clang" \
		CFLAGS="-g3 -ggdb $(call check_compiler_many,$(DEBUG_FLAGS)) $(LIBFUZZER_FLAGS)" \
		CPPFLAGS="-DPAX_UTILS_LIBFUZZ=1" \
		$(LIBFUZZER_TARGETS)

compile.c = $(CC) $(CFLAGS) $(CPPFLAGS) $(CPPFLAGS-$<) -o $@ -c $<

ifeq ($(V),)
Q := @
else
Q :=
endif
%.o: %.c
ifeq ($(V),)
	@echo $(compile.c)
endif
	$(Q)$(compile.c) $(WFLAGS)

LINK = $(CC) $(CFLAGS) $(LDFLAGS) $^ -o $@ $(LIBS) $(LIBS-$@)

$(BUILD_TARGETS): %: $(BUILD_OBJS) %.o; $(LINK)
$(ELF_TARGETS): %: $(ELF_OBJS) $(COMMON_OBJS) %.o; $(LINK)
$(MACH_TARGETS): %: $(MACH_OBJS) $(COMMON_OBJS) %.o; $(LINK)

$(OBJS_TARGETS): %: $(_OBJS) %.c
	$(CC) $(CFLAGS) $(CPPFLAGS) -DMAIN $(LDFLAGS) $(filter-out $@.o,$^) -o $@ $(LIBS) $(LIBS-$@)

seccomp-bpf.h: seccomp-bpf.c
	$(MAKE) BUILD_USE_SECCOMP=yes seccomp-bpf
	./seccomp-bpf > $@

depend:
	$(CC) $(CFLAGS) -MM $(SOURCES) > .depend

clean:
	-rm -f $(OBJS) $(TARGETS) $(OBJS_TARGETS) $(BUILD_TARGETS)

distclean: clean
	-rm -f *~ core *.o
	-cd man && $(MAKE) clean
strip: all
	$(STRIP) $(TARGETS)
strip-more:
	$(STRIP) --strip-unneeded $(TARGETS)

install: all
	$(MKDIR) $(PREFIX)/bin/ $(MANDIR)/man1/ $(PKGDOCDIR)/
	for sh in $(SCRIPTS_SH) ; do $(INS_EXE) $$sh.sh $(PREFIX)/bin/$$sh || exit $$? ; done
ifneq ($(USE_PYTHON),no)
	for py in $(SCRIPTS_PY) ; do $(INS_EXE) $$py.py $(PREFIX)/bin/$$py || exit $$? ; done
endif
	$(INS_EXE) $(TARGETS) $(PREFIX)/bin/
	$(INS_DATA) README.md BUGS TODO $(PKGDOCDIR)/

PN = pax-utils
P = $(PN)-$(PV)
dist:
	./make-tarball.sh $(SHELL_TRACE) $(DISTCHECK) $(PV)
distcheck:
	$(MAKE) dist DISTCHECK=--check

-include .depend

check test:
	$(MAKE) -C tests

.PHONY: all check clean dist install test

#
# All logic related to autotools is below here
#
GEN_MARK_START = \# @@@ GEN START @@@ \#
GEN_MARK_END   = \# @@@ GEN END @@@ \#
EXTRA_DIST     = $(shell git ls-files | grep -v -E '^(\.github|travis)/')
autotools-update:
	$(MAKE) -C man -j
	sed -i.tmp '/^$(GEN_MARK_START)$$/,/^$(GEN_MARK_END)$$/d' Makefile.am
	@rm -f Makefile.am.tmp
	( \
		echo "$(GEN_MARK_START)"; \
		printf 'dist_man_MANS +='; \
		printf ' \\\n\t%s' `printf '%s\n' man/*.1 | LC_ALL=C sort`; \
		echo; \
		printf 'EXTRA_DIST +='; \
		printf ' \\\n\t%s' $(EXTRA_DIST); \
		echo; \
		echo "$(GEN_MARK_END)"; \
	) >> Makefile.am
autotools:
ifeq ($(SKIP_AUTOTOOLS_UPDATE),)
	$(MAKE) autotools-update
endif
	./autogen.sh $(SHELL_TRACE) --from=make

.PHONY: autotools autotools-update _autotools-update
