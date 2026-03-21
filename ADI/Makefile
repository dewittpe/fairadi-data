include ../Makevars

ADITOPICS := topic01.csv.gz topic02.csv.gz topic03.csv.gz topic04.csv.gz topic05.csv.gz topic06.csv.gz topic07.csv.gz topic08.csv.gz topic09.csv.gz topic10.csv.gz topic11.csv.gz topic12.csv.gz topic13.csv.gz topic14.csv.gz topic15.csv.gz topic16.csv.gz topic17.csv.gz
ADITOPIC_CSV := $(ADITOPICS:.csv.gz=.csv)

acsvar = $(foreach year,$(ACS5_YEARS),../ACS5/$(1)__$(year).csv.gz)

.INTERMEDIATE: $(ADITOPIC_CSV) total_population.csv housing_units.csv group_quarters.csv adi.csv
.PHONY: all clean

all: adi.csv.gz

%.csv.gz: %.csv
	gzip -9 -f -n $<

adi.csv: adi.R adi_utilities.R $(ADITOPICS) total_population.csv.gz housing_units.csv.gz group_quarters.csv.gz
	$(RSCRIPTVANILLA) $<

total_population.csv: total_population.R adi_utilities.R $(call acsvar,B01003)
	$(RSCRIPTVANILLA) $<

housing_units.csv: housing_units.R adi_utilities.R $(call acsvar,B25001)
	$(RSCRIPTVANILLA) $<

group_quarters.csv: group_quarters.R adi_utilities.R ../Decennial/P18__2020.csv.gz ../Decennial/P1__2020.csv.gz total_population.csv.gz
	$(RSCRIPTVANILLA) $<

topic01.csv: topic01.R adi_utilities.R $(call acsvar,B15003)
	$(RSCRIPTVANILLA) $<

topic02.csv: topic02.R adi_utilities.R $(call acsvar,B15003)
	$(RSCRIPTVANILLA) $<

topic03.csv: topic03.R adi_utilities.R $(call acsvar,C24010)
	$(RSCRIPTVANILLA) $<

topic04.csv: topic04.R adi_utilities.R $(call acsvar,B19113)
	$(RSCRIPTVANILLA) $<

topic05.csv: topic05.R adi_utilities.R $(call acsvar,B19001) total_population.csv.gz
	$(RSCRIPTVANILLA) $<

topic06.csv: topic06.R adi_utilities.R $(call acsvar,B25077)
	$(RSCRIPTVANILLA) $<

topic07.csv: topic07.R adi_utilities.R $(call acsvar,B25063)
	$(RSCRIPTVANILLA) $<

topic08.csv: topic08.R adi_utilities.R $(call acsvar,B25087)
	$(RSCRIPTVANILLA) $<

topic09.csv: topic09.R adi_utilities.R $(call acsvar,B25003)
	$(RSCRIPTVANILLA) $<

topic10.csv: topic10.R adi_utilities.R $(call acsvar,B23025)
	$(RSCRIPTVANILLA) $<

topic11.csv: topic11.R adi_utilities.R $(call acsvar,B17010)
	$(RSCRIPTVANILLA) $<

topic12.csv: topic12.R adi_utilities.R $(call acsvar,C17002)
	$(RSCRIPTVANILLA) $<

topic13.csv: topic13.R adi_utilities.R $(call acsvar,B11012)
	$(RSCRIPTVANILLA) $<

topic14.csv: topic14.R adi_utilities.R $(call acsvar,B25044)
	$(RSCRIPTVANILLA) $<

topic15.csv: topic15.R adi_utilities.R $(call acsvar,B28002) $(call acsvar,B25043)
	$(RSCRIPTVANILLA) $<

topic16.csv: topic16.R adi_utilities.R $(call acsvar,B25047)
	$(RSCRIPTVANILLA) $<

topic17.csv: topic17.R adi_utilities.R $(call acsvar,B25014)
	$(RSCRIPTVANILLA) $<
