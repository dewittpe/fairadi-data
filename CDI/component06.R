################################################################################
# file: component06.R
#
# Build component 6 of the CDI
#
# Component: 6 OLD - use phone status pre 2017
# ACS Data Table:
#   B25043
# Table Name:
#   Tenure by Telephone Service Available by Age of Householder
# Numerator Calculation:
#   B25043_007 + B25043_016
# Denominator Calculation:
#   B25043_001
# Value Calculation with Description:
#   (No telephone (owner occupied) + No telephone (renter occupied)) / total
#
# Component: 6 - 2017 and beyond
#   Households without high-speed internet, %
# ACS Data Table:
#   B28002
# Table Name:
#   Presence and types of internet subscriptions in household
# Numerator Calculation:
#   B28002_003 + B28002_0013
# Denominator Calculation:
#   B28002_001
# Value Calculation with Description:
#   [Dial-up with no other type of Internet subscription (B28002_003) + No Internet access (B28002_013)]/Total (B28002_001)
################################################################################
source("cdi_utilities.R")

# import needed data
pre2017 <- import_census_table(table = "B25043")
post2017 <- import_census_table(table = "B28002")

cfa <- check_for_annotations(pre2017)
stopifnot(identical(cfa, list(E = character(0), M = character(0))))
cfa <- check_for_annotations(post2017)
stopifnot(identical(cfa, list(E = character(0), M = character(0))))

pre2017  <- subset(pre2017, year < 2017)
post2017 <- subset(post2017, year >= 2017)

# Step 1: build the component
# Step 2: build the MOE
nV <- sprintf("B25043_%03d", c(7, 16))
dV <- sprintf("B25043_%03d", 1)
pre2017 <- steps_1_and_2(pre2017, 6, nV, dV)

nV <- sprintf("B28002_%03d", c(3, 13))
dV <- sprintf("B28002_%03d", 1)
post2017 <- steps_1_and_2(post2017, 6, nV, dV)

# Step 3: flag for replacement
pre2017  <- join_tphu(pre2017)
post2017 <- join_tphu(post2017)

pre2017[
  ,
  flag_for_replacement := data.table::fcase(
    B25043_001E == 0, 1L,
    default = flag_for_replacement
  )
]

post2017[
  ,
  flag_for_replacement := data.table::fcase(
    B28002_001E == 0, 1L,
    default = flag_for_replacement
  )
]

# Step 4 and 5: Apply Shrinkage to account for sampling error, and coalese by
# geography level
pre2017  <- steps_4_and_5(pre2017,  "component06")
post2017 <- steps_4_and_5(post2017, "component06")

# build as one data set
DT <- rbind(pre2017, post2017)

# Step 6: Standardize the component
DT[, component06 := scale(component06), by = .(year)]

# Steps 7, 8, and 9 are done in faircdi.R

# save this data to disk
# only need block group level data to be saved
DT <- subset(DT, !is.na(block_group))
data.table::fwrite(DT, file = "component06.csv")

################################################################################
#                                 End of File                                  #
################################################################################
