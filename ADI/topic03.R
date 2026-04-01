################################################################################
# file: topic03.R
#
# Objective: build topic03 of the Area Deprivation Index
#
#   Topic: 3
#   Topic Area: % Employed ≥ 16 yrs in White-Collar Occs.
#   Detailed Table ID: C24010
#   Calculations:
#      Numerator:
#        C24010_003E  Male: Management, business, science, and arts occupations
#      + C24010_027E  Male: Sales and office occupations
#      + C24010_039E  Female: Management, business, science, and arts occupations
#      + C24010_063E  Female: Sales and office occupations
#      Denominator: C24010_001E
#
#   Notes:
#     Use only top-level mutually exclusive occupation groups.
#     Do not sum nested subcategories beneath these groups, or the numerator
#     will double count workers.
#
# C24010_001E  Total
# C24010_002E  Male:
# C24010_003E  Male:   !! Management, business, science, and arts occupations:
# C24010_004E  Male:   !! Management, business, science, and arts occupations:          !! Management, business, and financial occupations:
# C24010_005E  Male:   !! Management, business, science, and arts occupations:          !! Management, business, and financial occupations:                  !! Management occupations
# C24010_006E  Male:   !! Management, business, science, and arts occupations:          !! Management, business, and financial occupations:                  !! Business and financial operations occupations
# C24010_007E  Male:   !! Management, business, science, and arts occupations:          !! Computer, engineering, and science occupations:
# C24010_008E  Male:   !! Management, business, science, and arts occupations:          !! Computer, engineering, and science occupations:                   !! Computer and mathematical occupations
# C24010_009E  Male:   !! Management, business, science, and arts occupations:          !! Computer, engineering, and science occupations:                   !! Architecture and engineering occupations
# C24010_010E  Male:   !! Management, business, science, and arts occupations:          !! Computer, engineering, and science occupations:                   !! Life, physical, and social science occupations
# C24010_011E  Male:   !! Management, business, science, and arts occupations:          !! Education, legal, community service, arts, and media occupations:
# C24010_012E  Male:   !! Management, business, science, and arts occupations:          !! Education, legal, community service, arts, and media occupations: !! Community and social service occupations
# C24010_013E  Male:   !! Management, business, science, and arts occupations:          !! Education, legal, community service, arts, and media occupations: !! Legal occupations
# C24010_014E  Male:   !! Management, business, science, and arts occupations:          !! Education, legal, community service, arts, and media occupations: !! Educational instruction, and library occupations
# C24010_015E  Male:   !! Management, business, science, and arts occupations:          !! Education, legal, community service, arts, and media occupations: !! Arts, design, entertainment, sports, and media occupations
# C24010_016E  Male:   !! Management, business, science, and arts occupations:          !! Healthcare practitioners and technical occupations:
# C24010_017E  Male:   !! Management, business, science, and arts occupations:          !! Healthcare practitioners and technical occupations:               !! Health diagnosing and treating practitioners and other technical occupations
# C24010_018E  Male:   !! Management, business, science, and arts occupations:          !! Healthcare practitioners and technical occupations:               !! Health technologists and technicians
# C24010_019E  Male:   !! Service occupations:
# C24010_020E  Male:   !! Service occupations:                                          !! Healthcare support occupations
# C24010_021E  Male:   !! Service occupations:                                          !! Protective service occupations:
# C24010_022E  Male:   !! Service occupations:                                          !! Protective service occupations:                                   !! Firefighting and prevention, and other protective service workers including supervisors
# C24010_023E  Male:   !! Service occupations:                                          !! Protective service occupations:                                   !! Law enforcement workers including supervisors
# C24010_024E  Male:   !! Service occupations:                                          !! Food preparation and serving related occupations
# C24010_025E  Male:   !! Service occupations:                                          !! Building and grounds cleaning and maintenance occupations
# C24010_026E  Male:   !! Service occupations:                                          !! Personal care and service occupations
# C24010_027E  Male:   !! Sales and office occupations:
# C24010_028E  Male:   !! Sales and office occupations:                                 !! Sales and related occupations
# C24010_029E  Male:   !! Sales and office occupations:                                 !! Office and administrative support occupations
# C24010_030E  Male:   !! Natural resources, construction, and maintenance occupations:
# C24010_031E  Male:   !! Natural resources, construction, and maintenance occupations: !! Farming, fishing, and forestry occupations
# C24010_032E  Male:   !! Natural resources, construction, and maintenance occupations: !! Construction and extraction occupations
# C24010_033E  Male:   !! Natural resources, construction, and maintenance occupations: !! Installation, maintenance, and repair occupations
# C24010_034E  Male:   !! Production, transportation, and material moving occupations:
# C24010_035E  Male:   !! Production, transportation, and material moving occupations:  !! Production occupations
# C24010_036E  Male:   !! Production, transportation, and material moving occupations:  !! Transportation occupations
# C24010_037E  Male:   !! Production, transportation, and material moving occupations:  !! Material moving occupations
# C24010_038E  Female:
# C24010_039E  Female: !! Management, business, science, and arts occupations:
# C24010_040E  Female: !! Management, business, science, and arts occupations:          !! Management, business, and financial occupations:
# C24010_041E  Female: !! Management, business, science, and arts occupations:          !! Management, business, and financial occupations:                  !! Management occupations
# C24010_042E  Female: !! Management, business, science, and arts occupations:          !! Management, business, and financial occupations:                  !! Business and financial operations occupations
# C24010_043E  Female: !! Management, business, science, and arts occupations:          !! Computer, engineering, and science occupations:
# C24010_044E  Female: !! Management, business, science, and arts occupations:          !! Computer, engineering, and science occupations:                   !! Computer and mathematical occupations
# C24010_045E  Female: !! Management, business, science, and arts occupations:          !! Computer, engineering, and science occupations:                   !! Architecture and engineering occupations
# C24010_046E  Female: !! Management, business, science, and arts occupations:          !! Computer, engineering, and science occupations:                   !! Life, physical, and social science occupations
# C24010_047E  Female: !! Management, business, science, and arts occupations:          !! Education, legal, community service, arts, and media occupations:
# C24010_048E  Female: !! Management, business, science, and arts occupations:          !! Education, legal, community service, arts, and media occupations: !! Community and social service occupations
# C24010_049E  Female: !! Management, business, science, and arts occupations:          !! Education, legal, community service, arts, and media occupations: !! Legal occupations
# C24010_050E  Female: !! Management, business, science, and arts occupations:          !! Education, legal, community service, arts, and media occupations: !! Educational instruction, and library occupations
# C24010_051E  Female: !! Management, business, science, and arts occupations:          !! Education, legal, community service, arts, and media occupations: !! Arts, design, entertainment, sports, and media occupations
# C24010_052E  Female: !! Management, business, science, and arts occupations:          !! Healthcare practitioners and technical occupations:
# C24010_053E  Female: !! Management, business, science, and arts occupations:          !! Healthcare practitioners and technical occupations:               !! Health diagnosing and treating practitioners and other technical occupations
# C24010_054E  Female: !! Management, business, science, and arts occupations:          !! Healthcare practitioners and technical occupations:               !! Health technologists and technicians
# C24010_055E  Female: !! Service occupations:
# C24010_056E  Female: !! Service occupations:                                          !! Healthcare support occupations
# C24010_057E  Female: !! Service occupations:                                          !! Protective service occupations:
# C24010_058E  Female: !! Service occupations:                                          !! Protective service occupations:                                   !! Firefighting and prevention, and other protective service workers including supervisors
# C24010_059E  Female: !! Service occupations:                                          !! Protective service occupations:                                   !! Law enforcement workers including supervisors
# C24010_060E  Female: !! Service occupations:                                          !! Food preparation and serving related occupations
# C24010_061E  Female: !! Service occupations:                                          !! Building and grounds cleaning and maintenance occupations
# C24010_062E  Female: !! Service occupations:                                          !! Personal care and service occupations
# C24010_063E  Female: !! Sales and office occupations:
# C24010_064E  Female: !! Sales and office occupations:                                 !! Sales and related occupations
# C24010_065E  Female: !! Sales and office occupations:                                 !! Office and administrative support occupations
# C24010_066E  Female: !! Natural resources, construction, and maintenance occupations:
# C24010_067E  Female: !! Natural resources, construction, and maintenance occupations: !! Farming, fishing, and forestry occupations
# C24010_068E  Female: !! Natural resources, construction, and maintenance occupations: !! Construction and extraction occupations
# C24010_069E  Female: !! Natural resources, construction, and maintenance occupations: !! Installation, maintenance, and repair occupations
# C24010_070E  Female: !! Production, transportation, and material moving occupations:
# C24010_071E  Female: !! Production, transportation, and material moving occupations:  !! Production occupations
# C24010_072E  Female: !! Production, transportation, and material moving occupations:  !! Transportation occupations
# C24010_073E  Female: !! Production, transportation, and material moving occupations:  !! Material moving occupations
#
################################################################################
source("../utilities/import_census_table.R")
source("../utilities/check_for_annotations.R")
source("adi_utilities.R")
DT <- import_census_table("C24010")
cfa <- check_for_annotations(DT)
stopifnot(identical(cfa, list(E = character(0), M = character(0))))

# focus on block_group
DT <- subset(DT, !is.na(block_group))

numerator_variables <- sprintf("C24010_%03dE", c(3, 27, 39, 63))

DT[
  ,
  topic03 := data.table::fifelse(
               C24010_001E > 0,
               rowSums(.SD, na.rm = TRUE) / C24010_001E,
               NA_real_
             ),
  .SDcols = numerator_variables
  ]

# Sanity check, all the proportions should be less than 1
stopifnot(all(DT[["topic03"]] <= 1.00, na.rm = TRUE))

# what about the missing values?  Check that all the missing values are due to a
# zero denominator.
DT[C24010_001E == 0L,  topic03_notes := "QDI-ZD"]
DT[is.na(C24010_001E), topic03_notes := "QDI-ZD"]

stopifnot(
  DT[is.na(topic03), all(C24010_001E == 0, na.rm = TRUE)],
  DT[topic03_notes == "QDI-ZD", all(is.na(topic03))],
  DT[is.na(topic03_notes), !any(is.na(topic03))]
)

# save the output to disk
cols_to_keep <-
  c(COLS_TO_KEEP,
    "topic03",
    "topic03_notes"
  )

DT <- DT[, .SD, .SDcols = cols_to_keep]
data.table::setcolorder(DT, neworder = cols_to_keep)
data.table::setkeyv(DT, cols = COLS_TO_KEEP)
data.table::fwrite(DT, file = "topic03.csv")

################################################################################
#                                 End of File                                  #
################################################################################
