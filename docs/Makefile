#
# Makefile for building Inca THRF WG documentation
#

include Makefile.inc

.PHONY: 

default: 
	@echo "Inca Documentation";
	@echo;
	@echo "Available targets:";
	@echo "  <doc>.<fmt> where <doc> = [${TARGETS}] and";
	@echo "                    <fmt> = [pdf,html,rtf]";
	@echo "  <doc>       where <doc> = [${TARGETS}]";
	@echo "              Creates html, pdf, and rtf for doc";
	@echo "  all         Creates all html, pdf, and rtf files";
	@echo "  clean       Deletes generated docbook files";
	@echo "  clean-all   Does 'clean' and deletes html, pdf, and rtf files";
	@echo "  distclean   Does 'clean-all' and deletes autoconf generated";
	@echo "              files";

all: $(TARGETS)

$(TARGETS): 
	make $@.html
	make $@.pdf
	make $@.rtf

%.sgml %.html:
	$(DB2HTML) "$(TOP_DIR)/config/ldp.dsl$(HTML_MODE)" $(CATALOG) -o publish/html --nochunks  src/$*.sgml
	mkdir -p publish/html/stylesheet-images; cp config/stylesheet-images/*.gif publish/html/stylesheet-images
	cp config/inca.css publish/html/inca.css
	rm -rf publish/html/figures; mkdir -p publish/html/figures; cp -r src/figures publish/html
	mkdir -p publish/html/schemas; cp src/schemas/*.xsd publish/html/schemas

%.sgml %.pdf:
	$(DB2PDF) "$(TOP_DIR)/config/ldp.dsl$(PDF_MODE)" $(CATALOG) -o publish/pdf src/$*.sgml

%.sgml %.rtf:
	$(DB2RTF) "$(TOP_DIR)/config/ldp.dsl$(PDF_MODE)" $(CATALOG) -o publish/rtf src/$*.sgml

clean:
	rm -rf publish/*
	rm -rf docbook2html-dir docbook2html-dir.junk

clean-all: clean

distclean: clean-all
	rm -f config/ldp.dsl Makefile.inc config.log config.status

