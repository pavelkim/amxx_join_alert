VERSION := $(shell cat .version )
PLATFORM := $(shell uname -s | tr [A-Z] [a-z])
PWD = $(shell pwd)

PROGNAME = amxx_join_alert.amxx
PROGNAME_VERSION = $(PROGNAME)-$(VERSION)
SOURCE_FILENAME = amxx_join_alert.sma
TARGZ_FILENAME = $(PROGNAME)-$(VERSION).tar.gz
TARGZ_CONTENTS = ${PROGNAME} README.md Makefile .version
LOGFILE = ${PROGNAME_VERSION}-build.log

PLUGIN_COMPILER_BASEDIR = build/linux
PLUGIN_COMPILER_INCLUDE = build/include
PLUGIN_COMPILER = ${PLUGIN_COMPILER_BASEDIR}/amxxpc
LD_LIBRARY_PATH = $(PLUGIN_COMPILER_BASEDIR)
.PHONY: all version build clean install test

$(TARGZ_FILENAME):
	mkdir -vp "$(PROGNAME_VERSION)"
	cp -v $(TARGZ_CONTENTS) "$(PROGNAME_VERSION)/"
	tar -zvcf "$(TARGZ_FILENAME)" "$(PROGNAME_VERSION)"

$(PROGNAME):
	sed -e "s/#define VERSION.*/#define VERSION \"${VERSION}\"/" "$(SOURCE_FILENAME)" > "$(SOURCE_FILENAME).ready"
	LD_LIBRARY_PATH="$(LD_LIBRARY_PATH)" ${PLUGIN_COMPILER} -i"$(PLUGIN_COMPILER_INCLUDE)" "$(SOURCE_FILENAME).ready" -o"$(PROGNAME)" | tee "${LOGFILE}"

test:
	@echo "Not implemented yet"

install:
	@echo "Not implemented yet"

clean:
	rm -vf "$(PROGNAME)"
	rm -vf "$(LOGFILE)"
	rm -rf "$(PROGNAME_VERSION)"
	rm -vf "$(SOURCE_FILENAME).ready"
	rm -vf "$(TARGZ_FILENAME)"

build: $(PROGNAME)

compress: $(TARGZ_FILENAME)
