include ../../Makevars
SHELL := /bin/bash

FIPS_DIR := ../../FIPS
OUTDIR ?= .
FETCH := ../../utilities/census_fetch.sh

ifeq ($(strip $(OUTDIR)),)
OUTDIR := .
endif

STATE_FIPS_FILES := $(foreach year,$(ACS5_YEARS),$(FIPS_DIR)/$(year)__states.csv)
MISSING_STATE_FIPS := $(filter-out $(wildcard $(STATE_FIPS_FILES)),$(STATE_FIPS_FILES))

ifneq ($(MISSING_STATE_FIPS),)
$(error Missing $(MISSING_STATE_FIPS). Run `make -C $(FIPS_DIR)` first.)
endif

define get_state_fips
$(shell tail -n +2 $(FIPS_DIR)/$(1)__states.csv | cut -d, -f1 | tr -d '"')
endef

OUTPUTS := $(foreach year,$(ACS5_YEARS), \
					 $(foreach tab,$(filter-out $(foreach pair,$(filter %__$(year),$(ACS5_EXCLUDE)),$(patsubst %__$(year),%,$(pair))),$(ACS5_TABLES)), \
					 $(foreach fips,$(call get_state_fips,$(year)), \
					 $(OUTDIR)/$(year)/$(fips)/$(tab).csv.gz)))

.PHONY: all

all: $(OUTPUTS)

$(OUTDIR)/%.csv.gz:
	$(eval TEMP_LIST := $(subst /, , $*))
	$(eval year := $(word 1,$(TEMP_LIST)))
	$(eval state := $(word 2,$(TEMP_LIST)))
	$(eval tab := $(word 3,$(TEMP_LIST)))
	@$(REQUIRE_API_KEY); \
	raw="$@.raw"; \
	tmp="$@.tmp"; \
	mkdir -p "$(dir $@)"; \
	url="https://api.census.gov/data/$(year)/acs/acs5?get=group($(tab))&for=block%20group:*&in=state:$(state)&in=county:*&in=tract:*&outputFormat=csv&key=$(API_KEY)"; \
	echo " Writing $@"; \
	$(FETCH) "$$url" "$$raw"; \
	gzip -9c "$$raw" > "$$tmp"; \
	mv -f "$$tmp" "$@"; \
	rm -f "$$raw"
