PACKAGE = tarantool-microb-module
DESCRIBE = $(subst -, ,$(shell (git describe || echo 1.0-1))) 0
VERSION = $(word 1,$(DESCRIBE))
RELEASE = $(word 2,$(DESCRIBE))
RPMROOT = ${HOME}/rpmbuild
TARBALL = $(RPMROOT)/SOURCES/$(PACKAGE).tar.gz
SPEC = $(RPMROOT)/SPECS/$(PACKAGE).spec

FILES = microb/ start_web.lua start_storage.lua start_runner.lua README.md

all: rpm

$(SPEC):
	mkdir -p $(RPMROOT)/SPECS
	cp microb.spec $@
	sed -i -e 's/^Version: [0-9.]*$$/Version: $(VERSION)/' -e 's/^Release: [0-9]*$$/Release: $(RELEASE)/' $@

$(TARBALL): $(FILES) microb.spec
	mkdir -p $(RPMROOT)/SOURCES
	$(eval TEMPDIR := $(shell mktemp -d))
	mkdir $(TEMPDIR)/$(PACKAGE)
	cp -ar $(FILES) $(TEMPDIR)/$(PACKAGE)
	cd $(TEMPDIR) && tar -cvzf $@ $(PACKAGE)/
	rm -rf $(TEMPDIR)

rpm: clean $(TARBALL) $(SPEC)
	rpmbuild -bb $(SPEC) --clean
	rm -f $(TARBALL) $(SPEC)
	@echo "RPM package is built in $(RPMROOT)"

clean:
	rm -f $(RPMROOT)/RPMS/*/$(PACKAGE)-$(VERSION)-$(RELEASE).*.rpm
	rm -f $(TARBALL) $(SPEC)

.PHONY : all clean
