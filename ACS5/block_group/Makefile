include ../../Makevars
SHELL := /bin/bash

FIPS_DIR := ../../FIPS
OUTDIR ?= .
FETCH := ../../utilities/census_fetch.sh
ACS5_BLOCK_GROUP_API_UNSUPPORTED_YEARS := 2010 2011 2012
SUMMARY_IMPORT := ../../utilities/build_acs5_summary_block_group.py
SUMMARY_CACHE_DIR := ../../ACS5/summary_cache

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

.PHONY: all check_api_support

all: $(OUTPUTS)

check_api_support:
	@unsupported="$(filter $(ACS5_BLOCK_GROUP_API_UNSUPPORTED_YEARS),$(ACS5_YEARS))"; \
	if [ -n "$$unsupported" ]; then \
		echo "ACS5 block-group API is unsupported for years: $$unsupported." >&2; \
		echo "The public Census API exposes tract geography for 2010-2012 ACS5, but not block group geography." >&2; \
		echo "Use the ACS5 Summary File workflow for those years; the API block-group path works starting in 2013." >&2; \
		exit 1; \
	fi

$(OUTDIR)/%.csv.gz:
	$(eval TEMP_LIST := $(subst /, , $*))
	$(eval year := $(word 1,$(TEMP_LIST)))
	$(eval state := $(word 2,$(TEMP_LIST)))
	$(eval tab := $(word 3,$(TEMP_LIST)))
	@mkdir -p "$(dir $@)"; \
	if echo " $(ACS5_BLOCK_GROUP_API_UNSUPPORTED_YEARS) " | grep -q " $(year) "; then \
		echo " Writing $@ via ACS5 Summary File"; \
		python3 $(SUMMARY_IMPORT) \
			--year $(year) \
			--state $(state) \
			--table $(tab) \
			--states-csv $(FIPS_DIR)/$(year)__states.csv \
			--cache-dir $(SUMMARY_CACHE_DIR) \
			--output $@; \
	else \
		$(REQUIRE_API_KEY); \
		raw="$@.raw"; \
		tmp="$@.tmp"; \
		url="https://api.census.gov/data/$(year)/acs/acs5?get=group($(tab))&for=block%20group:*&in=state:$(state)&in=county:*&in=tract:*&outputFormat=csv&key=$(API_KEY)"; \
		echo " Writing $@"; \
		$(FETCH) "$$url" "$$raw"; \
		gzip -9c "$$raw" > "$$tmp"; \
		mv -f "$$tmp" "$@"; \
		rm -f "$$raw"; \
	fi
