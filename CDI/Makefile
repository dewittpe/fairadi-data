include ../Makevars

UTILITIES := ../utilities/import_census_table.R ../utilities/check_for_annotations.R cdi_utilities.R

COMPONENTS := component01.csv.gz component02.csv.gz component03.csv.gz component04.csv.gz component05.csv.gz component06.csv.gz component07.csv.gz component08.csv.gz component09.csv.gz component10.csv.gz component11.csv.gz component12.csv.gz component13.csv.gz component14.csv.gz component15.csv.gz component16.csv.gz component17.csv.gz
COMPONENT_CSV := $(COMPONENTS:.csv.gz=.csv)

acsvar = $(foreach year,$(ACS5_YEARS),../ACS5/$(1)__$(year).csv.gz)

.INTERMEDIATE: $(COMPONENT_CSV) total_population_and_housing_units.csv
.PHONY: all clean

all: $(COMPONENTS)

%.csv.gz: %.csv
	gzip -9 -f -n $<

faircdi.csv: faircdi.R cdi_utilities.R $(COMPONENTS)
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

total_population_and_housing_units.csv: total_population_and_housing_units.R $(call acsvar,B01001) $(call acsvar,B01003) $(call acsvar,B25032) $(UTILITIES)
	$(RSCRIPTVANILLA) $<


#README.md: README.Rmd faircdi.csv.gz
#	$(RSCRIPTVANILLA) -e "knitr::knit('$<', output='$@')"

clean:
	$(RM) -r cache/
