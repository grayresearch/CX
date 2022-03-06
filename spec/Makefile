HEADER_SOURCE := spec.adoc
PDF_RESULT := spec.pdf
SOURCES := $(HEADER_SOURCE)

all: $(PDF_RESULT)

.PHONY: $(PDF_RESULT)
$(PDF_RESULT): $(SOURCES)
	sed -e '1,/^$$/d' <README.md >preface.adoc
	asciidoctor-pdf \
    --attribute=mathematical-format=svg \
    --attribute=pdf-fontsdir=resources/fonts \
    --attribute=pdf-style=theme.yml \
    --failure-level=ERROR \
    --require=asciidoctor-bibtex \
    --require=asciidoctor-diagram \
    --require=asciidoctor-mathematical \
    --out-file=$@ \
    $(HEADER_SOURCE)
