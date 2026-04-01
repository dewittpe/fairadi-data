include ../../Makevars
SHELL := /bin/bash

OUTDIR ?= .
FETCH := ../../utilities/census_fetch.sh

ifeq ($(strip $(OUTDIR)),)
OUTDIR := .
endif

OUTPUTS := $(foreach year,$(DECENNIAL_YEARS), \
					 $(foreach tab,$(call decennial_tables,$(year)), \
					 $(OUTDIR)/$(year)/$(tab).csv.gz))

.PHONY: all

all: $(OUTPUTS)

$(OUTDIR)/%.csv.gz:
	$(eval TEMP_LIST := $(subst /, , $*))
	$(eval year := $(word 1,$(TEMP_LIST)))
	$(eval tab := $(word 2,$(TEMP_LIST)))
	$(eval dataset := $(call decennial_dataset,$(year)))
	@$(REQUIRE_API_KEY); \
	raw="$@.raw"; \
	tmp="$@.tmp"; \
	mkdir -p "$(dir $@)"; \
	url="https://api.census.gov/data/$(year)/dec/$(dataset)?get=group($(tab))&for=state:*&outputFormat=csv&key=$(API_KEY)"; \
	echo " Writing $@"; \
	$(FETCH) "$$url" "$$raw"; \
	gzip -9c "$$raw" > "$$tmp"; \
	mv -f "$$tmp" "$@"; \
	rm -f "$$raw"
