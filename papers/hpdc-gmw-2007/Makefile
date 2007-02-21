
DOC=paper
DVIPS=dvips
PS2PDF=pstopdf
LATEX2RTF=latex2rtf
ALLTEX=$(wildcard *.tex)
REDUCE=psnup -n 2

all: $(DOC).dvi 

spelling: 
	ispell -t $(ALLTEX)

clean:
	rm -f $(DOC).dvi $(DOC).aux *.aux $(DOC).log $(DOC).bbl $(DOC).blg \
	$(DOC).ps $(DOC).pdf \
	$(DOC).lot $(DOC).lof $(DOC).toc
	
view: $(DOC).pdf
	open -a Preview $(DOC).pdf 

update:
	rm -f $(DOC).ps $(DOC).pdf
	cvs update

word: $(DOC).rtf
	open -a /Applications/Microsoft\ Office\ 2004/Microsoft\ Word $(DOC).rtf

$(DOC).rtf: $(DOC).tex
	$(LATEX2RTF) $(DOC).tex

$(DOC).ps: $(DOC).dvi
	$(DVIPS) $(DOC).dvi -Ppdf -t letter -o $(DOC).ps

$(DOC).pdf: $(DOC).ps
	$(PS2PDF) $(DOC).ps

$(DOC).2.ps: $(DOC).ps
	$(REDUCE) $(DOC).ps > $(DOC).2.ps

$(DOC).aux: $(ALLTEX)
	latex $(DOC)

$(DOC).bbl: $(DOC).bib $(DOC).aux
	bibtex $(DOC)
	latex $(DOC)

$(DOC).dvi: $(DOC).tex $(DOC).bbl
	latex $(DOC)

