include ../../Makevars
SHELL := /bin/bash

OUTDIR ?= .
FETCH := ../../utilities/census_fetch.sh

ifeq ($(strip $(OUTDIR)),)
OUTDIR := .
endif

DECENNIAL_DATASET ?= dhc

OUTPUTS := $(foreach year,$(DECENNIAL_YEARS), \
					 $(foreach tab,$(DECENNIAL_TABLES), \
					 $(OUTDIR)/$(year)/$(tab).csv.gz))

.PHONY: all

all: $(OUTPUTS)

$(OUTDIR)/%.csv.gz:
	$(eval TEMP_LIST := $(subst /, , $*))
	$(eval year := $(word 1,$(TEMP_LIST)))
	$(eval tab := $(word 2,$(TEMP_LIST)))
	@$(REQUIRE_API_KEY); \
	raw="$@.raw"; \
	tmp="$@.tmp"; \
	mkdir -p "$(dir $@)"; \
	url="https://api.census.gov/data/$(year)/dec/$(DECENNIAL_DATASET)?get=group($(tab))&for=state:*&outputFormat=csv&key=$(API_KEY)"; \
	echo " Writing $@"; \
	$(FETCH) "$$url" "$$raw"; \
	gzip -9c "$$raw" > "$$tmp"; \
	mv -f "$$tmp" "$@"; \
	rm -f "$$raw"
