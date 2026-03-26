SHELL := /bin/bash
include ../Makevars

OUTPUTS := $(foreach year,$(DECENNIAL_YEARS),$(foreach tab,$(DECENNIAL_TABLES), $(tab)__$(year).csv.gz))
METADATA_OUTPUTS := $(foreach year,$(DECENNIAL_YEARS),$(foreach tab,$(DECENNIAL_TABLES), metadata/$(year)/$(tab).json))

.PHONY: all metadata state county tract block_group block-group clean

all: $(OUTPUTS) $(METADATA_OUTPUTS)

metadata: $(METADATA_OUTPUTS)

state:
	$(MAKE) -C state

county:
	$(MAKE) -C county

tract:
	$(MAKE) -C tract

block_group:
	$(MAKE) -C block_group

block-group: block_group

%.csv.gz: %.csv
	gzip -n -f -9 $<

%.csv: ../utilities/stacktogether.R | state county tract block_group
	$(RSCRIPTVANILLA) $< $*

metadata/%.json:
	$(eval TEMP_LIST := $(subst /, , $*))
	$(eval year := $(word 1,$(TEMP_LIST)))
	$(eval tab := $(word 2,$(TEMP_LIST)))
	@mkdir -p "$(dir $@)"; \
	url="https://api.census.gov/data/$(year)/dec/$(DECENNIAL_DATASET)/groups/$(tab).json"; \
	echo " Writing $@"; \
	../utilities/census_fetch.sh "$$url" "$@"

clean:

# ------------------------------------------------------------------------------
