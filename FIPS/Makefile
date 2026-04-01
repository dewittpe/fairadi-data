SHELL := /bin/bash
include ../Makevars
FETCH := ../utilities/census_fetch.sh
CSV_TOOL := ../utilities/census_csv_tool.py
PYTHON ?= python3

STATE_CSV := $(foreach year,$(FIPS_YEARS),$(year)__states.csv)
COUNTY_CSV := $(foreach year,$(FIPS_YEARS),$(year)__counties.csv)
TRACT_PAIRS := $(foreach year,$(FIPS_YEARS),$(year)__tract_pairs.txt)
TRACT_CSV := $(foreach year,$(FIPS_YEARS),$(year)__tracts.csv)
BLOCK_GROUP_CSV := $(foreach year,$(FIPS_YEARS),$(year)__block_groups.csv)

.PHONY: all clean

all: $(STATE_CSV) $(COUNTY_CSV) $(TRACT_CSV) $(BLOCK_GROUP_CSV)

%__states.csv:
	@$(REQUIRE_API_KEY); \
	raw="$@.raw"; \
	tmp="$@.tmp"; \
	dataset="$(call fips_dataset,$*)"; \
	url="https://api.census.gov/data/$*/$$dataset?get=NAME&for=state:*&outputFormat=csv&key=$(API_KEY)"; \
	echo " Writing $@"; \
	$(FETCH) "$$url" "$$raw"; \
	$(PYTHON) $(CSV_TOOL) project --input "$$raw" --output "$$tmp" --columns state,NAME; \
	{ echo '"state","name"'; tail -n +2 "$$tmp" | sort -t, -k1,1n; } > "$@"; \
	dos2unix -q "$@"; \
	rm -f "$$raw" "$$tmp"

%__counties.csv:
	@$(REQUIRE_API_KEY); \
	raw="$@.raw"; \
	tmp="$@.tmp"; \
	dataset="$(call fips_dataset,$*)"; \
	url="https://api.census.gov/data/$*/$$dataset?get=NAME&for=county:*&in=state:*&outputFormat=csv&key=$(API_KEY)"; \
	echo " Writing $@"; \
	$(FETCH) "$$url" "$$raw"; \
	$(PYTHON) $(CSV_TOOL) project --input "$$raw" --output "$$tmp" --columns state,county,NAME; \
	{ echo '"state","county","name"'; tail -n +2 "$$tmp" | sort -t, -k1,1n -k2,2n; } > "$@"; \
	dos2unix -q "$@"; \
	rm -f "$$raw" "$$tmp"

%__tract_pairs.txt: %__counties.csv
	tail -n +2 $< | cut -d, -f1,2 | tr -d '"' | awk -F, '{print $$1 "/" $$2}' | sort -u > $@

tracts/%.csv:
	$(eval TEMP_LIST := $(subst /, , $*))
	$(eval year_make := $(word 1,$(TEMP_LIST)))
	$(eval dataset := $(call fips_dataset,$(year_make)))
	@$(REQUIRE_API_KEY); \
	parts=($$(echo "$*" | tr / ' ')); \
	year="$${parts[0]}"; \
	state="$${parts[1]}"; \
	county="$${parts[2]}"; \
	url="https://api.census.gov/data/$$year/$(dataset)?get=NAME&for=tract:*&in=state:$$state&in=county:$$county&outputFormat=csv&key=$(API_KEY)"; \
	echo " Writing $@"; \
	$(FETCH) "$$url" "$@"; \
	dos2unix -q "$@"

%__tracts.csv: %__tract_pairs.txt
	@tmp="$@.tmp"; \
	rm -f "$$tmp"; \
	fail=0; \
	while IFS=/ read -r state county; do \
		csv="tracts/$*/$$state/$$county.csv"; \
		if [ ! -s "$$csv" ]; then \
			if ! $(MAKE) "$$csv"; then \
				fail=1; \
				continue; \
			fi; \
		fi; \
		if ! $(PYTHON) $(CSV_TOOL) project --input "$$csv" --output - --columns state,county,tract,NAME | tail -n +2 >> "$$tmp"; then \
			fail=1; \
		fi; \
	done < $<; \
	if [ "$$fail" -ne 0 ] || [ ! -s "$$tmp" ]; then \
		rm -f "$$tmp"; \
		exit 1; \
	fi; \
	{ \
		echo '"state","county","tract","name"'; \
		sort -t, -k1,1n -k2,2n -k3,3n "$$tmp"; \
	} > "$@"; \
	dos2unix -q "$@"; \
	rm -f "$$tmp"

block_groups/%.csv:
	$(eval TEMP_LIST := $(subst /, , $*))
	$(eval year_make := $(word 1,$(TEMP_LIST)))
	$(eval dataset := $(call fips_dataset,$(year_make)))
	@$(REQUIRE_API_KEY); \
	parts=($$(echo "$*" | tr / ' ')); \
	year="$${parts[0]}"; \
	state="$${parts[1]}"; \
	county="$${parts[2]}"; \
	url="https://api.census.gov/data/$$year/$(dataset)?get=NAME&for=block%20group:*&in=state:$$state&in=county:$$county&outputFormat=csv&key=$(API_KEY)"; \
	echo " Writing $@"; \
	$(FETCH) "$$url" "$@"; \
	dos2unix -q "$@"

%__block_groups.csv: %__tract_pairs.txt
	@tmp="$@.tmp"; \
	rm -f "$$tmp"; \
	fail=0; \
	while IFS=/ read -r state county; do \
		csv="block_groups/$*/$$state/$$county.csv"; \
		if [ ! -s "$$csv" ]; then \
			if ! $(MAKE) "$$csv"; then \
				fail=1; \
				continue; \
			fi; \
		fi; \
		if ! $(PYTHON) $(CSV_TOOL) project --input "$$csv" --output - --columns state,county,tract,block\ group,NAME | tail -n +2 >> "$$tmp"; then \
			fail=1; \
		fi; \
	done < $<; \
	if [ "$$fail" -ne 0 ] || [ ! -s "$$tmp" ]; then \
		rm -f "$$tmp"; \
		exit 1; \
	fi; \
	{ \
		echo '"state","county","tract","block_group","name"'; \
		sort -t, -k1,1n -k2,2n -k3,3n -k4,4n "$$tmp"; \
	} > "$@"; \
	dos2unix -q "$@"; \
	rm -f "$$tmp"
