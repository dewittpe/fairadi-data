include ../Makevars

UTILITIES := ../utilities/import_census_table.R ../utilities/check_for_annotations.R ../utilities/verify_integer.R

ADITOPICS := topic01.csv.gz topic02.csv.gz topic03.csv.gz topic04.csv.gz topic05.csv.gz topic06.csv.gz topic07.csv.gz topic08.csv.gz topic09.csv.gz topic10.csv.gz topic11.csv.gz topic12.csv.gz topic13.csv.gz topic14.csv.gz topic15.csv.gz topic16.csv.gz topic17.csv.gz
ADITOPIC_CSV := $(ADITOPICS:.csv.gz=.csv)

acsvar = $(foreach year,$(call acs5_years_for,$(1)),../ACS5/$(1)__$(year).csv.gz)

.INTERMEDIATE: $(ADITOPIC_CSV) total_population.csv housing_units.csv group_quarters.csv fairadi.csv
.PHONY: all clean

all: README.md

%.csv.gz: %.csv
	gzip -9 -f -n $<

fairadi.csv: fairadi.R adi_utilities.R $(ADITOPICS) total_population.csv.gz housing_units.csv.gz group_quarters.csv.gz ../utilities/build_FIPS.R
	$(RSCRIPTVANILLA) $<

total_population.csv: total_population.R adi_utilities.R $(call acsvar,B01003)
	$(RSCRIPTVANILLA) $<

housing_units.csv: housing_units.R adi_utilities.R $(call acsvar,B25001)
	$(RSCRIPTVANILLA) $<

group_quarters.csv: group_quarters.R adi_utilities.R ../Decennial/P18__2020.csv.gz ../Decennial/P1__2020.csv.gz total_population.csv.gz
	$(RSCRIPTVANILLA) $<

topic01.csv: topic01.R adi_utilities.R $(call acsvar,B15003) $(UTILITIES)
	$(RSCRIPTVANILLA) $<

topic02.csv: topic02.R adi_utilities.R $(call acsvar,B15003) $(UTILITIES)
	$(RSCRIPTVANILLA) $<

topic03.csv: topic03.R adi_utilities.R $(call acsvar,C24010) $(UTILITIES)
	$(RSCRIPTVANILLA) $<

topic04.csv: topic04.R adi_utilities.R $(call acsvar,B19013) $(UTILITIES)
	$(RSCRIPTVANILLA) $<

topic05.csv: topic05.R adi_utilities.R $(call acsvar,B19001) total_population.csv.gz $(UTILITIES)
	$(RSCRIPTVANILLA) $<

topic06.csv: topic06.R adi_utilities.R $(call acsvar,B25077) $(UTILITIES)
	$(RSCRIPTVANILLA) $<

topic07.csv: topic07.R adi_utilities.R $(call acsvar,B25064) $(UTILITIES)
	$(RSCRIPTVANILLA) $<

topic08.csv: topic08.R adi_utilities.R $(call acsvar,B25088) $(UTILITIES)
	$(RSCRIPTVANILLA) $<

topic09.csv: topic09.R adi_utilities.R $(call acsvar,B25003) $(UTILITIES)
	$(RSCRIPTVANILLA) $<

topic10.csv: topic10.R adi_utilities.R $(call acsvar,B23025) $(UTILITIES)
	$(RSCRIPTVANILLA) $<

topic11.csv: topic11.R adi_utilities.R $(call acsvar,B17010) $(UTILITIES)
	$(RSCRIPTVANILLA) $<

topic12.csv: topic12.R adi_utilities.R $(call acsvar,C17002) $(UTILITIES)
	$(RSCRIPTVANILLA) $<

topic13.csv: topic13.R adi_utilities.R $(call acsvar,B11003) $(UTILITIES)
	$(RSCRIPTVANILLA) $<

topic14.csv: topic14.R adi_utilities.R $(call acsvar,B25044) $(UTILITIES)
	$(RSCRIPTVANILLA) $<

topic15.csv: topic15.R adi_utilities.R $(call acsvar,B28002) $(call acsvar,B25043) $(UTILITIES)
	$(RSCRIPTVANILLA) $<

topic16.csv: topic16.R adi_utilities.R $(call acsvar,B25047) $(UTILITIES)
	$(RSCRIPTVANILLA) $<

topic17.csv: topic17.R adi_utilities.R $(call acsvar,B25014) $(UTILITIES)
	$(RSCRIPTVANILLA) $<

README.md: README.Rmd fairadi.csv.gz
	$(RSCRIPTVANILLA) -e "knitr::knit('$<', output='$@')"

clean:
	$(RM) -r cache/
