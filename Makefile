# Do not edit -- this file documents how Postfix was built for your machine.
#----------------------------------------------------------------
# Start of summary of user-configurable 'make makefiles' options.
# CCARGS=
# AUXLIBS=
# shared=
# dynamicmaps=
# pie=
# End of summary of user-configurable 'make makefiles' options.
#--------------------------------------------------------------
# System-dependent settings and compiler/linker overrides.
SYSTYPE	= NETBSD1
_AR	= ar
ARFL	= rv
_RANLIB	= ranlib
SYSLIBS	= -L/usr/pkg/lib -Wl,-R/usr/pkg/lib -lpcre2-8 
CC	= owcc -I. -I../../include -DNO_EAI -DHAS_DEV_URANDOM -DHAS_PCRE=2 -I/usr/pkg/include -UUSE_DYNAMIC_LIBS -DDEF_SHLIB_DIR=\"no\" -UUSE_DYNAMIC_MAPS $(WARN)
OPT	= -O
DEBUG	= -g
AWK	= awk
STRCASE = 
EXPORT	= CCARGS='-I. -I../../include -DNO_EAI -DHAS_DEV_URANDOM -DHAS_PCRE=2 -I/usr/pkg/include -UUSE_DYNAMIC_LIBS -DDEF_SHLIB_DIR=\"no\" -UUSE_DYNAMIC_MAPS' OPT='-O' DEBUG='-g'
WARN	= -Wall -Wno-comment -Wformat -Wimplicit -Wmissing-prototypes \
	-Wparentheses -Wstrict-prototypes -Wswitch -Wuninitialized \
	-Wunused -Wno-missing-braces -fno-common
DEFINED_MAP_TYPES = dev_urandom pcre
MAKE_FIX = 
# Switch between Postfix static and dynamically-linked libraries.
AR	= ar
RANLIB	= ranlib
LIB_PREFIX = 
LIB_SUFFIX = .a
SHLIB_CFLAGS = 
SHLIB_DIR = no
SHLIB_ENV = 
SHLIB_LD = :
SHLIB_SYSLIBS = 
SHLIB_RPATH = 
# Switch between dynamicmaps.cf plugins and hard-linked databases.
NON_PLUGIN_MAP_OBJ = $(MAP_OBJ)
PLUGIN_MAP_OBJ = 
PLUGIN_MAP_OBJ_UPDATE = 
PLUGIN_MAP_SO_MAKE = 
PLUGIN_MAP_SO_UPDATE = 
PLUGIN_LD = 
POSTFIX_INSTALL_OPTS = 
# Application-specific rules.
# To test with valgrind:
# make -i tests NORANDOMIZE="" VALGRIND="valgrind --tool=memcheck --log-file=/some/where.%p" 
SHELL	= /bin/sh
WARN    = -Wmissing-prototypes -Wformat -Wno-comment -fno-common
OPTS	= 'WARN=$(WARN)'
DIRS	= src/util src/global src/dns src/tls src/xsasl src/master src/milter \
	src/postfix src/fsstone src/smtpstone \
	src/sendmail src/error src/pickup src/cleanup src/smtpd src/local \
	src/trivial-rewrite src/qmgr src/oqmgr src/smtp src/bounce \
	src/pipe src/showq src/postalias src/postcat src/postconf src/postdrop \
	src/postkick src/postlock src/postlog src/postmap src/postqueue \
	src/postsuper src/qmqpd src/spawn src/flush src/verify \
	src/virtual src/proxymap src/anvil src/scache src/discard src/tlsmgr \
	src/postmulti src/postscreen src/dnsblog src/tlsproxy \
	src/posttls-finger src/postlogd
MANDIRS	= proto man html
LIBEXEC	= libexec/post-install libexec/postfix-script libexec/postfix-wrapper \
	libexec/postmulti-script libexec/postfix-tls-script
META	= meta/main.cf.proto meta/master.cf.proto meta/postfix-files \
	meta/makedefs.out $(PLUGINS)
EXPAND	= sed -e "s;\$${LIB_PREFIX};$(LIB_PREFIX);" \
	    -e "s;\$${LIB_SUFFIX};$(LIB_SUFFIX);"
SHLIB_DIR_OVERRIDE = \
	$${shlib_directory:-`$(SHLIB_ENV) bin/postconf -dhx shlib_directory`}

default: update

# While generating the top-level Makefile, we must get the PLUGIN_LD
# setting directly from the latest makedefs.out result.

makefiles Makefiles conf/makedefs.out:
	(echo "# Do not edit -- this file documents how Postfix was built for your machine."; $(SHELL) makedefs) >makedefs.tmp
	set +e; if cmp makedefs.tmp conf/makedefs.out; then rm makedefs.tmp; \
	else mv makedefs.tmp conf/makedefs.out; fi >/dev/null 2>/dev/null
	set -e; for i in $(DIRS); do \
	 (set -e; echo "[$$i]"; cd $$i; rm -f Makefile; \
	 $(MAKE) -f Makefile.in Makefile MAKELEVEL=) || exit 1; \
	done
	@set -- `grep '^PLUGIN_LD' conf/makedefs.out`; \
	rm -f Makefile; (cat conf/makedefs.out; \
	case  "$$3" in \
	""|":") grep -v '^PLUGINS' Makefile.in;; \
	     *) cat Makefile.in;; \
	esac) >Makefile

update printfck tests root_tests:
	set -e; for i in $(DIRS); do \
	 (set -e; echo "[$$i]"; cd $$i; $(MAKE) $(OPTS) $@ MAKELEVEL=) || exit 1; \
	done

update: $(META) $(LIBEXEC)

libexec/post-install: conf/post-install
	rm -f $@ && ln -f $? $@

# Censor out build directory information.

meta/makedefs.out: conf/makedefs.out
	grep -v SHLIB_ENV $? > $@

meta/postfix-files: conf/postfix-files conf/makedefs.out Makefile
	rm -f $@
	(if [ "${SHLIB_DIR}" = "no" -o "${SHLIB_DIR}" = "" ]; then \
	    sed -e '/^\$$shlib_directory/d' \
		-e '/dynamicmaps.cf/d' conf/postfix-files; \
	elif [ "${PLUGIN_LD}" = ":" -o "${PLUGIN_LD}" = "" ]; then \
	    sed -e '/dynamicmaps.cf/d' \
		-e '/^\$$shlib_directory\/\$${LIB_PREFIX}/d' \
		conf/postfix-files | $(EXPAND); \
	else \
	    $(EXPAND) conf/postfix-files | awk -F: ' \
		BEGIN { \
		    count = split("'"$(DEFINED_MAP_TYPES)"'", names, " "); \
		    for (n = 1; n <= count; n++) \
			have["$$shlib_directory/$(LIB_PREFIX)" names[n] \
			    "$(LIB_SUFFIX)"] = 1; } \
		/^[$$]shlib_directory.$(LIB_PREFIX)/ { \
		    if (have[$$1]) print; next } \
		{ print } \
	    '; \
	fi) | case "$(MAKE_FIX)" in \
	 *) cat;; \
	esac > $@

libexec/postfix-script: conf/postfix-script
	rm -f $@ && ln -f $? $@

libexec/postfix-tls-script: conf/postfix-tls-script
	rm -f $@ && ln -f $? $@

libexec/postfix-wrapper: conf/postfix-wrapper
	rm -f $@ && ln -f $? $@

meta/main.cf.proto: conf/main.cf
	rm -f $@ && ln -f $? $@

meta/master.cf.proto: conf/master.cf
	rm -f $@ && ln -f $? $@

libexec/postmulti-script: conf/postmulti-script
	rm -f $@ && ln -f $? $@

meta/dynamicmaps.cf: conf/dynamicmaps.cf Makefile
	rm -f $@ && $(EXPAND) conf/dynamicmaps.cf | $(AWK) ' \
		BEGIN { split("'"$(DEFINED_MAP_TYPES)"'", map_types); \
			for (n in map_types) has_type[map_types[n]] = n } \
		/^#/ { print } \
		/^[a-z]/ { if (has_type[$$1]) print } \
	' >$@

manpages:
	set -e; for i in $(MANDIRS); do \
	 (set -e; echo "[$$i]"; cd $$i; $(MAKE) -f Makefile.in $(OPTS) MAKELEVEL=) || exit 1; \
	done </dev/null

# Some checks require a bin/postconf executable.
pre-release-checks: typo-check missing-proxy-read-maps-check \
	postlink-check postfix-files-check

postfix-files-check:
	mantools/check-postfix-files | diff /dev/null -

postlink-check:
	$(SHLIB_ENV) mantools/check-postlink | diff /dev/null -

missing-proxy-read-maps-check:
	$(SHLIB_ENV) mantools/missing-proxy-read-maps | diff /dev/null -

typo-check: spell-cc spell-install-proto-text spell-proto-html \
	double-cc double-install-proto-text double-proto-html

spell-cc:
	mantools/check-spell-cc | diff /dev/null -

spell-install-proto-text:
	mantools/check-spell-install-proto-text | diff /dev/null -

spell-proto-html:
	mantools/check-spell-proto-html | diff /dev/null -

double-cc:
	mantools/check-double-cc | diff /dev/null -

double-install-proto-text:
	mantools/check-double-install-proto-text | diff /dev/null -

double-proto-html:
	mantools/check-double-proto-html | diff /dev/null -

# The build-time shlib_directory setting must take precedence over
# the installed main.cf settings, otherwise we can't update an
# installed system from dynamicmaps=yes<->dynamicmaps=no or from
# shared=yes<->shared=no.

install: update
	SHLIB_ENV_VAR= SHLIB_ENV_VAL= \
	$(SHLIB_ENV) shlib_directory=$(SHLIB_DIR_OVERRIDE) $(SHELL) \
		postfix-install $(POSTFIX_INSTALL_OPTS)

package: update
	SHLIB_ENV_VAR= SHLIB_ENV_VAL= \
	$(SHLIB_ENV) shlib_directory=$(SHLIB_DIR_OVERRIDE) $(SHELL) \
		postfix-install -package $(POSTFIX_INSTALL_OPTS)

upgrade: update
	SHLIB_ENV_VAR= SHLIB_ENV_VAL= \
	$(SHLIB_ENV) shlib_directory=$(SHLIB_DIR_OVERRIDE) $(SHELL) \
		postfix-install -non-interactive $(POSTFIX_INSTALL_OPTS)
	

non-interactive-package: update
	SHLIB_ENV_VAR= SHLIB_ENV_VAL= \
	$(SHLIB_ENV) shlib_directory=$(SHLIB_DIR_OVERRIDE) $(SHELL) \
		postfix-install -non-interactive -package $(POSTFIX_INSTALL_OPTS)

depend clean:
	set -e; for i in $(DIRS); do \
	 (set -e; echo "[$$i]"; cd $$i; $(MAKE) $@) || exit 1; \
	done

depend_update:
	set -e; for i in $(DIRS); do \
	 (set -e; echo "[$$i]"; cd $$i; $(MAKE) depend && $(MAKE) $(OPTS) update) \
	    || exit 1; \
	done

tidy:	clean
	rm -f Makefile */Makefile src/*/Makefile
	cp -p Makefile.init Makefile
	rm -f README_FILES/RELEASE_NOTES
	ln -s ../RELEASE_NOTES README_FILES
	rm -f bin/[!CRS]* lib/[!CRS]* include/[!CRS]* libexec/[!CRS]* \
	    src/*/libpostfix-*.so src/*/libpostfix-*.dylib \
	    src/*/postfix-*.so src/*/postfix-*.dylib \
	    junk */junk */*/junk \
	    *core */*core */*/*core \
	    .nfs* */.nfs* */*/.nfs* \
	    .pure */.pure */*/.pure \
	    *.out */*.out */*/*.out \
	    *.tmp */*.tmp */*/*.tmp \
	    *.a */*.a */*/*.a \
	    *~ */*~ */*/*~ \
	    *- */*- */*/*- \
	    *.orig */*.orig */*/*.orig \
	    *.bak */*.bak */*/*.bak \
	    make.err */make.err */*/make.err \
	    *.gmon */*.gmon */*/*.gmon \
	    conf/main.cf.default conf/bounce.cf.default meta/*
	find . -type s -print | xargs rm -f
	find . -type d -print | xargs chmod 755
	find . -type f -print | xargs chmod a+r
