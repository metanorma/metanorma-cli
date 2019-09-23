#!make
SHELL := /bin/bash
# Ensure the xml2rfc cache directory exists locally
IGNORE := $(shell mkdir -p $(HOME)/.cache/xml2rfc)

SRC := $(shell yq r metanorma.yml metanorma.source.files | cut -c 3-999)
ifeq ($(SRC),ll)
SRC := $(filter-out README.adoc, $(wildcard *.adoc))
endif

FORMAT_MARKER := mn-output-
FORMATS := $(shell grep "$(FORMAT_MARKER)" $(SRC) | cut -f 2 -d ' ' | tr ',' '\n' | sort | uniq | tr '\n' ' ')

XML  := $(patsubst %.adoc,%.xml,$(SRC))
XMLRFC3  := $(patsubst %.adoc,%.v3.xml,$(SRC))
HTML := $(patsubst %.adoc,%.html,$(SRC))
DOC  := $(patsubst %.adoc,%.doc,$(SRC))
PDF  := $(patsubst %.adoc,%.pdf,$(SRC))
TXT  := $(patsubst %.adoc,%.txt,$(SRC))
NITS := $(patsubst %.adoc,%.nits,$(wildcard draft-*.adoc))
WSD  := $(wildcard models/*.wsd)
XMI	 := $(patsubst models/%,xmi/%,$(patsubst %.wsd,%.xmi,$(WSD)))
PNG	 := $(patsubst models/%,images/%,$(patsubst %.wsd,%.png,$(WSD)))

COMPILE_CMD_LOCAL := bundle exec metanorma $$FILENAME
COMPILE_CMD_DOCKER := docker run -v "$$(pwd)":/metanorma/ ribose/metanorma "metanorma $$FILENAME"

ifdef METANORMA_DOCKER
  COMPILE_CMD := echo "Compiling via docker..."; $(COMPILE_CMD_DOCKER)
else
  COMPILE_CMD := echo "Compiling locally..."; $(COMPILE_CMD_LOCAL)
endif

_OUT_FILES := $(foreach FORMAT,$(FORMATS),$(shell echo $(FORMAT) | tr '[:lower:]' '[:upper:]'))
OUT_FILES  := $(foreach F,$(_OUT_FILES),$($F))

all: images $(OUT_FILES)

%.v3.xml %.xml %.html %.doc %.pdf %.txt:	%.adoc | bundle
	FILENAME=$^; \
	${COMPILE_CMD}

draft-%.nits:	draft-%.txt
	VERSIONED_NAME=`grep :name: draft-$*.adoc | cut -f 2 -d ' '`; \
	cp $^ $${VERSIONED_NAME}.txt && \
	idnits --verbose $${VERSIONED_NAME}.txt > $@ && \
	cp $@ $${VERSIONED_NAME}.nits && \
	cat $${VERSIONED_NAME}.nits

%.nits:

nits: $(NITS)

images: $(PNG)

images/%.png: models/%.wsd
	plantuml -tpng -o ../images/ $<

xmi: $(XMI)

xmi/%.xmi: models/%.wsd
	plantuml -xmi:star -o ../xmi/ $<

define FORMAT_TASKS
OUT_FILES-$(FORMAT) := $($(shell echo $(FORMAT) | tr '[:lower:]' '[:upper:]'))

open-$(FORMAT):
	open $$(OUT_FILES-$(FORMAT))

clean-$(FORMAT):
	rm -f $$(OUT_FILES-$(FORMAT))

$(FORMAT): clean-$(FORMAT) $$(OUT_FILES-$(FORMAT))

.PHONY: clean-$(FORMAT)

endef

$(foreach FORMAT,$(FORMATS),$(eval $(FORMAT_TASKS)))

open: open-html

clean:
	rm -f $(OUT_FILES) && rm -rf published

bundle:
	if [ "x" == "${METANORMA_DOCKER}x" ]; then bundle; fi

.PHONY: bundle all open clean

#
# Watch-related jobs
#

.PHONY: watch serve watch-serve

NODE_BINS          := onchange live-serve run-p
NODE_BIN_DIR       := node_modules/.bin
NODE_PACKAGE_PATHS := $(foreach PACKAGE_NAME,$(NODE_BINS),$(NODE_BIN_DIR)/$(PACKAGE_NAME))

$(NODE_PACKAGE_PATHS): package.json
	npm i

watch: $(NODE_BIN_DIR)/onchange
	$(MAKE) all
	$< $(ALL_SRC) -- $(MAKE) all

define WATCH_TASKS
watch-$(FORMAT): $(NODE_BIN_DIR)/onchange
	$(MAKE) $(FORMAT)
	$$< $$(SRC_$(FORMAT)) -- $(MAKE) $(FORMAT)

.PHONY: watch-$(FORMAT)
endef

$(foreach FORMAT,$(FORMATS),$(eval $(WATCH_TASKS)))

serve: $(NODE_BIN_DIR)/live-server revealjs-css reveal.js images
	export PORT=$${PORT:-8123} ; \
	port=$${PORT} ; \
	for html in $(HTML); do \
		$< --entry-file=$$html --port=$${port} --ignore="*.html,*.xml,Makefile,Gemfile.*,package.*.json" --wait=1000 & \
		port=$$(( port++ )) ;\
	done

watch-serve: $(NODE_BIN_DIR)/run-p
	$< watch serve

#
# Deploy jobs
#

publish:
	$(MAKE) published

published:
	mkdir -p $@ && \
	export GLOBIGNORE=$(SRC); \
	cp -a $(addsuffix .*,$(basename $(SRC))) $@/; \
	unset GLOBIGNORE; \
	cp $(firstword $(HTML)) $@/index.html

.PHONY: publish

