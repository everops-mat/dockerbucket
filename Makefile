TANGLE=tclsh scripts/tangle.tcl
DOCKERFILES=ubi9+epel.dockerfile

.SUFFIXES: .md .dockerfile

.md.dockerfile:
	@$(TANGLE) -R $@ $< > $@

.PHONY: default
default: all

.PHONY: all
all: $(DOCKERFILES)

.PHONY: clean
clean:
	@rm -f *~
	@rm -rf $(DOCKERFILES)
