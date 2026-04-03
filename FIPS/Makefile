SHELL := /bin/bash
include ../Makevars
PYTHON ?= python3
BUILD := ../utilities/build_fips_from_tiger.py
CACHE_DIR := tiger

STATE_CSV := $(foreach year,$(FIPS_YEARS),$(year)__states.csv)
COUNTY_CSV := $(foreach year,$(FIPS_YEARS),$(year)__counties.csv)
TRACT_CSV := $(foreach year,$(FIPS_YEARS),$(year)__tracts.csv)
BLOCK_GROUP_CSV := $(foreach year,$(FIPS_YEARS),$(year)__block_groups.csv)

.PHONY: all clean

all: $(STATE_CSV) $(COUNTY_CSV) $(TRACT_CSV) $(BLOCK_GROUP_CSV)

%__states.csv: $(BUILD)
	@echo " Writing $@"; \
	$(PYTHON) $(BUILD) --year $* --level state --cache-dir $(CACHE_DIR) --output $@

%__counties.csv: %__states.csv $(BUILD)
	@echo " Writing $@"; \
	$(PYTHON) $(BUILD) --year $* --level county --cache-dir $(CACHE_DIR) --states $< --output $@

%__tracts.csv: %__counties.csv $(BUILD)
	@echo " Writing $@"; \
	$(PYTHON) $(BUILD) --year $* --level tract --cache-dir $(CACHE_DIR) --counties $< --output $@

%__block_groups.csv: %__tracts.csv $(BUILD)
	@echo " Writing $@"; \
	$(PYTHON) $(BUILD) --year $* --level block_group --cache-dir $(CACHE_DIR) --tracts $< --output $@

clean:
	rm -rf $(CACHE_DIR) *.raw *.tmp tracts block_groups *__tract_pairs.txt
