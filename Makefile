SHELL := /bin/bash
include Makevars

.PHONY: all manifest zenodo release fips acs5 acs5-state acs5-county acs5-tract acs5-block-group acs5-metadata decennial decennial-state decennial-county decennial-tract decennial-block-group decennial-metadata census-metadata adi

all: fips decennial acs5 adi manifest

fips:
	$(MAKE) -C FIPS

acs5: fips
	$(MAKE) -C ACS5

acs5-metadata:
	$(MAKE) -C ACS5 metadata

acs5-state: fips
	$(MAKE) -C ACS5 state

acs5-county: fips
	$(MAKE) -C ACS5 county

acs5-tract: fips
	$(MAKE) -C ACS5 tract

acs5-block-group: fips
	$(MAKE) -C ACS5 block-group

decennial: fips
	$(MAKE) -C Decennial

decennial-metadata:
	$(MAKE) -C Decennial metadata

census-metadata:
	$(MAKE) acs5-metadata
	$(MAKE) decennial-metadata

decennial-state: fips
	$(MAKE) -C Decennial state

decennial-county: fips
	$(MAKE) -C Decennial county

decennial-tract: fips
	$(MAKE) -C Decennial tract

decennial-block-group: fips
	$(MAKE) -C Decennial block-group

adi: acs5 decennial
	$(MAKE) -C ADI

manifest: adi
	./utilities/build_manifest.py

zenodo: manifest
	./utilities/zenodo_package.sh

release: all zenodo
