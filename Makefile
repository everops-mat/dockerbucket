TANGLE=tclsh scripts/tangle.tcl
ALL=$(shell ls *.md | grep -v README.md | sed s/\.md$$//)

.SUFFIXES: .md .dockerfile .test

.md.dockerfile:
	@$(TANGLE) -R $@ $< > $@
.md.test:
	$(TANGLE) -R $(@:%.test=%.dockerfile) $< | docker build -t mek:$@ -f - .

default: all

all: $(ALL:%=%.dockerfile)

test: $(ALL:%=%.test)

clean:
	@rm -f *~
	@rm -rf $(ALL:%=%.dockerfile)

install:
	@echo installing my-docker
	@install scripts/my-docker $(HOME)/bin/my-docker
	@echo installing my-docker man page
	@install scripts/my-docker.1 $(HOME)/man/man1/my-docker.1

.PHONY: default all clean test install

