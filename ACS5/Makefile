SHELL := /bin/bash
include ../Makevars

OUTPUTS := $(foreach pair,$(acs5_pairs),$(pair).csv.gz)
METADATA_OUTPUTS := $(foreach pair,$(acs5_pairs),metadata/$(call acs5_pair_year,$(pair))/$(call acs5_pair_table,$(pair)).json)

.PHONY: all metadata state county tract block_group clean

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

%.csv.gz: %.csv
	@set -e -o pipefail; \
	tmp="$@.tmp"; \
	gzip -n -9c "$<" > "$$tmp"; \
	$(PUBLISH_GZIP_CSV)

%.csv: ../utilities/stacktogether.R | state county tract block_group
	$(RSCRIPTVANILLA) $< $*

metadata/%.json:
	$(eval TEMP_LIST := $(subst /, , $*))
	$(eval year := $(word 1,$(TEMP_LIST)))
	$(eval tab := $(word 2,$(TEMP_LIST)))
	@set -e -o pipefail; \
	$(REQUIRE_API_KEY); \
	mkdir -p "$(dir $@)"; \
	tmp="$@.tmp"; \
	url="https://api.census.gov/data/$(year)/$(ACS5_DATASET)/groups/$(tab).json?key=$(API_KEY)"; \
	echo " Writing $@"; \
	../utilities/census_fetch.sh "$$url" "$$tmp"; \
	python3 -m json.tool "$$tmp" >/dev/null; \
	if [ -f "$@" ] && cmp -s "$@" "$$tmp"; then \
		rm -f "$$tmp"; \
	else \
		mv -f "$$tmp" "$@"; \
	fi

clean:

# ------------------------------------------------------------------------------
