include ../Makevars

UTILITIES := ../utilities/import_census_table.R ../utilities/check_for_annotations.R cdi_utilities.R

COMPONENTS := component01.csv.gz component02.csv.gz component03.csv.gz component04.csv.gz component05.csv.gz component06.csv.gz component07.csv.gz component08.csv.gz component09.csv.gz component10.csv.gz component11.csv.gz component12.csv.gz component13.csv.gz component14.csv.gz component15.csv.gz component16.csv.gz component17.csv.gz component18.csv.gz
COMPONENT_CSV := $(COMPONENTS:.csv.gz=.csv)

acsvar = $(foreach year,$(ACS5_YEARS),../ACS5/$(1)__$(year).csv.gz)

.INTERMEDIATE: $(COMPONENT_CSV) total_population_and_housing_units.csv faircdi.csv
.PHONY: all clean

all: README.md

%.csv.gz: %.csv
	gzip -9 -f -n $<

faircdi.csv: faircdi.R cdi_utilities.R $(COMPONENTS) ../utilities/build_FIPS.R
	$(RSCRIPTVANILLA) $<

component01.csv: component01.R cdi_utilities.R $(call acsvar,B15003) $(UTILITIES) total_population_and_housing_units.csv.gz
	$(RSCRIPTVANILLA) $<

component02.csv: component02.R cdi_utilities.R $(call acsvar,B15003) $(UTILITIES) total_population_and_housing_units.csv.gz
	$(RSCRIPTVANILLA) $<

component03.csv: component03.R cdi_utilities.R $(call acsvar,C24010) $(UTILITIES) total_population_and_housing_units.csv.gz
	$(RSCRIPTVANILLA) $<

component04.csv: component04.R cdi_utilities.R $(call acsvar,B17010) $(UTILITIES) total_population_and_housing_units.csv.gz
	$(RSCRIPTVANILLA) $<

component05.csv: component05.R cdi_utilities.R $(call acsvar,B25014) $(UTILITIES) total_population_and_housing_units.csv.gz
	$(RSCRIPTVANILLA) $<

component06.csv: component06.R cdi_utilities.R $(call acsvar,B28002) $(UTILITIES) total_population_and_housing_units.csv.gz
	$(RSCRIPTVANILLA) $<

component07.csv: component07.R cdi_utilities.R $(call acsvar,B25044) $(UTILITIES) total_population_and_housing_units.csv.gz
	$(RSCRIPTVANILLA) $<

component08.csv: component08.R cdi_utilities.R $(call acsvar,B25047) $(UTILITIES) total_population_and_housing_units.csv.gz
	$(RSCRIPTVANILLA) $<

component09.csv: component09.R cdi_utilities.R $(call acsvar,B19001) $(UTILITIES) total_population_and_housing_units.csv.gz
	$(RSCRIPTVANILLA) $<

component10.csv: component10.R cdi_utilities.R $(call acsvar,B19013) $(UTILITIES) total_population_and_housing_units.csv.gz
	$(RSCRIPTVANILLA) $<

component11.csv: component11.R cdi_utilities.R $(call acsvar,B25064) $(UTILITIES) total_population_and_housing_units.csv.gz
	$(RSCRIPTVANILLA) $<

component12.csv: component12.R cdi_utilities.R $(call acsvar,B25077) $(UTILITIES) total_population_and_housing_units.csv.gz
	$(RSCRIPTVANILLA) $<

component13.csv: component13.R cdi_utilities.R $(call acsvar,B25088) $(UTILITIES) total_population_and_housing_units.csv.gz
	$(RSCRIPTVANILLA) $<

component14.csv: component14.R cdi_utilities.R $(call acsvar,B11003) $(UTILITIES) total_population_and_housing_units.csv.gz
	$(RSCRIPTVANILLA) $<

component15.csv: component15.R cdi_utilities.R $(call acsvar,B25003) $(UTILITIES) total_population_and_housing_units.csv.gz
	$(RSCRIPTVANILLA) $<

component16.csv: component16.R cdi_utilities.R $(call acsvar,C17002) $(UTILITIES) total_population_and_housing_units.csv.gz
	$(RSCRIPTVANILLA) $<

component17.csv: component17.R cdi_utilities.R $(call acsvar,B23025) $(UTILITIES) total_population_and_housing_units.csv.gz
	$(RSCRIPTVANILLA) $<

component18.csv: component18.R cdi_utilities.R $(call acsvar,B27010) $(UTILITIES) total_population_and_housing_units.csv.gz
	$(RSCRIPTVANILLA) $<

total_population_and_housing_units.csv: total_population_and_housing_units.R $(call acsvar,B01001) $(call acsvar,B01003) $(call acsvar,B25032) $(UTILITIES)
	$(RSCRIPTVANILLA) $<

README.md: README.Rmd faircdi.csv.gz
	$(RSCRIPTVANILLA) -e "knitr::knit('$<', output='$@')"

clean:
	$(RM) -r cache/
