TANGLE=tclsh scripts/tangle.tcl
ALL=ubi9epel ubuntu fossil opensuse alpine

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

.PHONY: default all clean test

