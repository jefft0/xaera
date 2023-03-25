DESTDIR?=
PREFIX?=/usr/local
INSTALLBIN?=$(PREFIX)/bin
INSTALLLIB?=$(PREFIX)/lib
INSTALLMAN?=$(PREFIX)/man
INSTALLINCLUDE?=$(PREFIX)/include
INSTALLPC?=$(INSTALLLIB)/pkgconfig
LDCONFIG?=ldconfig

DPREFIX=$(DESTDIR)$(PREFIX)
DINSTALLBIN=$(DESTDIR)$(INSTALLBIN)
DINSTALLLIB=$(DESTDIR)$(INSTALLLIB)
DINSTALLMAN=$(DESTDIR)$(INSTALLMAN)
DINSTALLINCLUDE=$(DESTDIR)$(INSTALLINCLUDE)
DINSTALLPC=$(DESTDIR)$(INSTALLPC)

XDOTOOL_DIR=submodules/xdotool

WARNFLAGS+=-pedantic -Wall -W -Wundef \
           -Wendif-labels -Wshadow -Wpointer-arith \
           -Wcast-align -Wwrite-strings \
           -Winline \
           -Wdisabled-optimization -Wno-missing-field-initializers

CFLAGS?=-pipe -O2 $(WARNFLAGS)
CFLAGS+=$(CPPFLAGS)

LIBXDO_LIBS=-L/usr/X11R6/lib -L/usr/local/lib -lX11 -lXtst -lXinerama -lxkbcommon
INC=-I$(XDOTOOL_DIR) -I/usr/X11R6/include -I/usr/local/include -I/usr/include/gtk-3.0 -I/usr/include/glib-2.0 \
  -I/usr/lib/x86_64-linux-gnu/glib-2.0/include -I/usr/include/cairo -I/usr/include/pango-1.0 \
  -I/usr/include/harfbuzz -I/usr/include/gdk-pixbuf-2.0
CFLAGS+=$(INC) 

LIBXDO=$(XDOTOOL_DIR)/libxdo.so

.PHONY: all
all: xdotool.1 libxdo.$(LIBSUFFIX) libxdo.$(VERLIBSUFFIX) xdotool

.PHONY: static
static: xdotool.static

.PHONY: install-static
install-static: xdotool.static
	install -d $(DINSTALLBIN)
	install -m 755 xdotool.static $(DINSTALLBIN)/xdotool

xdotool.static: xdotool.o $(CMDOBJS) xdo.o xdo_search.o
	$(CC) -o xdotool.static xdotool.o xdo.o xdo_search.o $(CMDOBJS) $(LDFLAGS)  -lm $(XDOTOOL_LIBS) $(LIBXDO_LIBS)

.PHONY: install
install: pre-install installlib installprog installman installheader installpc post-install

.PHONY: pre-install
pre-install:
	install -d $(DPREFIX)

.PHONY: post-install
post-install:
	@if [ "$$(uname)" = "Linux" ] ; then \
		echo "Running ldconfig to update library cache"; \
		$(LDCONFIG) \
		  || echo "Failed running 'ldconfig'. Maybe you need to be root?"; \
	fi

.PHONY: installprog
installprog: xdotool
	install -d $(DINSTALLBIN)
	install -m 755 xdotool $(DINSTALLBIN)/

.PHONY: installlib
installlib: libxdo.$(LIBSUFFIX)
	install -d $(DINSTALLLIB)
	install libxdo.$(LIBSUFFIX) $(DINSTALLLIB)/libxdo.$(VERLIBSUFFIX)
	ln -sf libxdo.$(VERLIBSUFFIX) $(DINSTALLLIB)/libxdo.$(LIBSUFFIX)

.PHONY: installheader
installheader: xdo.h
	install -d $(DINSTALLINCLUDE)
	install -m 0644 xdo.h $(DINSTALLINCLUDE)/xdo.h

.PHONY: installpc
installpc: libxdo.pc
	install -d $(DINSTALLPC)
	install -m 0644 libxdo.pc $(DINSTALLPC)/libxdo.pc

.PHONY: installman
installman: xdotool.1
	install -d $(DINSTALLMAN)/man1
	install -m 644 xdotool.1 $(DINSTALLMAN)/man1/

.PHONY: deinstall
deinstall: uninstall

.PHONY: uninstall
uninstall: 
	rm -f $(DINSTALLBIN)/xdotool
	rm -f $(DINSTALLMAN)/xdotool.1
	rm -f $(DINSTALLLIB)/libxdo.$(LIBSUFFIX)
	rm -f $(DINSTALLLIB)/libxdo.$(VERLIBSUFFIX)

.PHONY: clean
clean:
	rm -f *.o xaera

xdo.o: xdo.c xdo_version.h
	$(CC) $(CFLAGS) -fPIC -c xdo.c

xdo_search.o: xdo_search.c
	$(CC) $(CFLAGS) -fPIC -c xdo_search.c

xdotool.o: xdotool.c xdo_version.h
	$(CC) $(CFLAGS) -c xdotool.c


xdo_search.c: xdo.h
xdo.c: xdo.h
xdotool.c: xdo.h

libxdo.$(LIBSUFFIX): xdo.o xdo_search.o
	$(CC) $(LDFLAGS) $(DYNLIBFLAG) $(LIBNAMEFLAG) xdo.o xdo_search.o -o $@ $(LIBXDO_LIBS)

libxdo.a: xdo.o xdo_search.o
	ar qv $@ xdo.o xdo_search.o

libxdo.$(VERLIBSUFFIX): libxdo.$(LIBSUFFIX)
	ln -s $< $@

libxdo.pc: VERSION
	sh pc.sh $(VERSION) $(INSTALLLIB) $(INSTALLINCLUDE) > libxdo.pc

# xdotool the binary requires libX11 now for XSelectInput and friends.
# This requirement will go away once more things are refactored into
# libxdo.
# TODO(sissel): only do this linker hack if we're using GCC?
xdotool: LDFLAGS+=-Xlinker
ifneq ($(WITHOUT_RPATH_FIX),1)
xdotool: LDFLAGS+=-rpath $(INSTALLLIB)
endif
xdotool: xdotool.o $(CMDOBJS) libxdo.$(LIBSUFFIX)
	$(CC) -o $@ xdotool.o $(CMDOBJS) -L. -lxdo $(LDFLAGS)  -lm $(XDOTOOL_LIBS)

xdotool.1: xdotool.pod
	pod2man -c "" -r "" xdotool.pod > $@

.PHONY: showman
showman: xdotool.1
	nroff -man $< | $$PAGER

.PHONY: docs
docs: Doxyfile xdo.h
	doxygen

xdotool.html: xdotool.pod
	pod2html $< > $@

.PHONY: package
package: test-package-build create-package create-package-deb

.PHONY: update-version
update-version:
	rm -f VERSION
	make VERSION xdo_version.h

.PHONY: package-deb
package-deb: test-package-build create-package-deb

.PHONY: test
test: WITH_SHELL=/bin/bash
test: xdotool libxdo.$(VERLIBSUFFIX)
	echo $(WITH_SHELL)
	if [ "$(WITH_SHELL)" = "/bin/sh" ] ; then \
		echo "Shell '$(WITH_SHELL)' fails on some Linux distros because it could"; \
		echo "be 'dash', a poorly implemented shell with bugs that break the"; \
		echo "tests. You need to use bash, zsh, or ksh to run the tests."; \
		exit 1; \
	fi
	SHELL=$(WITH_SHELL) $(MAKE) -C t

xdo_version.h: VERSION
	sh version.sh --header > $@

VERSION:
	sh version.sh --shell > $@

.PHONY: create-package
create-package: NAME=xdotool-$(VERSION)
create-package: xdo_version.h libxdo.pc
	echo "Creating package: $(NAME)"
	mkdir "$(NAME)"
	rsync --exclude '.*' -a `ls -d *.pod COPYRIGHT *.c *.h *.pc examples t CHANGELIST README.md Makefile* version.sh platform.sh cflags.sh VERSION Doxyfile 2> /dev/null` "$(NAME)/"
	tar -zcf "$(NAME).tar.gz" "$(NAME)"
	rm -r "$(NAME)"

# Make sure the package we're building compiles.
.PHONY: test-package-build
test-package-build: NAME=xdotool-$(VERSION)
test-package-build: create-package
	echo "Testing package $(NAME)"
	tar -zxf $(NAME).tar.gz
	make -C ./$(NAME)
	make -C ./$(NAME) docs
	make -C ./$(NAME) install DESTDIR=$(NAME)/install-test/ LDCONFIG=:
	make -C ./$(NAME) test
	rm -rf ./$(NAME)
	echo "Package ready: $(NAME)";


### Build .deb packages for xdotool. The target 'create-package-deb' will
# create {xdotool,xdotool-doc,libxdo$(MAJOR),libxdo$(MAJOR)-dev}*.deb packages
# The reason I do this is to avoid any madness involved in dealing with
# debuild, dh_make, and related tools. '.deb' packages are an 'ar' with two
# tarballs.

DEBDIR=deb-build
create-package-deb: VERSION xdo_version.h
	[ -d $(DEBDIR) ] && rm -r $(DEBDIR) || true
	$(MAKE) xdotool.deb xdotool-doc.deb libxdo$(MAJOR).deb libxdo$(MAJOR)-dev.deb

%.deb: $(DEBDIR)/usr
	$(MAKE) $(DEBDIR)/$*/data.tar.gz $(DEBDIR)/$*/control.tar.gz \
	        $(DEBDIR)/$*/debian-binary
	wd=$$PWD; \
	cd $(DEBDIR)/$*; \
	  ar -qc $$wd/$*_$(VERSION)-1_$(shell uname -m).deb \
	    debian-binary control.tar.gz data.tar.gz

$(DEBDIR)/usr:
	$(MAKE) install DESTDIR=$(DEBDIR) PREFIX=/usr INSTALLMAN=/usr/share/man

$(DEBDIR)/xdotool $(DEBDIR)/xdotool-doc $(DEBDIR)/libxdo$(MAJOR) $(DEBDIR)/libxdo$(MAJOR)-dev:
	mkdir -p $@

$(DEBDIR)/%/debian-binary:
	echo "2.0" > $@

# Generate the 'control' file
$(DEBDIR)/%/control: $(DEBDIR)/%/
	sed -e 's/%VERSION%/$(VERSION)/g; s/%MAJOR%/$(MAJOR)/' \
		ext/debian/$(shell echo $* | tr -d 0-9).control > $@

# Generate the 'md5sums' file 
$(DEBDIR)/%/md5sums: $(DEBDIR)/%/ $(DEBDIR)/%/data.tar.gz 
	tar -ztf $(DEBDIR)/$*/data.tar.gz | (cd $(DEBDIR); xargs md5sum || true) > $@

# Generate the 'control.tar.gz'
$(DEBDIR)/%/control.tar.gz: $(DEBDIR)/%/control $(DEBDIR)/%/md5sums
	tar -C $(DEBDIR)/$* -zcf $(DEBDIR)/$*/control.tar.gz control md5sums 

# Build a tarball for xdotool files
$(DEBDIR)/xdotool/data.tar.gz: $(DEBDIR)/xdotool
	tar -C $(DEBDIR) -zcf $@ usr/bin

# Build a tarball for libxdo# files
$(DEBDIR)/libxdo$(MAJOR)/data.tar.gz: $(DEBDIR)/libxdo$(MAJOR)
	tar -C $(DEBDIR) -zcf $@ usr/lib

# Build a tarball for libxdo#-dev files
$(DEBDIR)/libxdo$(MAJOR)-dev/data.tar.gz: $(DEBDIR)/libxdo$(MAJOR)-dev
	tar -C $(DEBDIR) -zcf $@ usr/include

# Build a tarball for xdotool-doc files
$(DEBDIR)/xdotool-doc/data.tar.gz: $(DEBDIR)/xdotool-doc
	tar -C $(DEBDIR) -zcf $@ usr/share

xaera.o: xaera.cpp
	$(CC) $(CFLAGS) -c xaera.cpp

xaera.cpp: $(XDOTOOL_DIR)/xdo.h

xaera: LDFLAGS+=-Xlinker -lgdk-3 -lgdk_pixbuf-2.0 -lgobject-2.0
xaera: xaera.o $(LIBXDO)
	$(CC) -o $@ xaera.o -L. -lxdo -lstdc++ $(LDFLAGS)  -lm $(XDOTOOL_LIBS)
