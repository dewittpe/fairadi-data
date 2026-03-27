################################################################################
# file: component09.R
#
# Build component 9 of the CDI
#
# Component: 9
#   Income disparity
# ACS Data Table:
#   B19001
# Table Name:
#   Household income in the paste 12 months
# Numerator Calculation:
#   sum of the items B19001_003 to B19001_004
# Denominator Calculation:
#   sum of the items B19001_014 to B19001_017
# Value Calculation with Description:
#   Log {100 * [Less than $20,000 (B19001_002 + … + B19001_004)/($100,000 to $124,999 (B19001_014) + …+ $200,000 or more (B19001_017))] }
################################################################################
source("cdi_utilities.R")

# import needed data
DT <- import_census_table(table = "B19001")
cfa <- check_for_annotations(DT)
stopifnot(identical(cfa, list(E = character(0), M = character(0))))

# Step 1: build the component
#
# The following special considerations are made for the income disparity
# component:
#
# • The income disparity component value conceptually represents the ratio of
#   low-income households (income ≤ $20,000) to high-income households
#   (income ≥ $100,000) in the specific block group.
# • A numerator of 0 indicates that there are no low-income households in the
#   block group.
# • A denominator of 0 indicates that there are no high-income households in the
#   block group.
# • To calculate the values of the income disparity component, follow the steps
#   below:
#   o Calculate the ratio for all block groups that have non-zero numerator
#     and denominator.
#   o Identify the highest disparity ratio and lowest disparity ratio calculated
#     in the previous step.
#   o For cases where the numerator of the income disparity component is 0 (i.e.
#     the ACS table indicates no households with low income), set the component
#     value to equal the minimum disparity ratio from the previous step.
#   o For cases where the denominator of the income disparity component is 0
#     (i.e. the ACS table indicates no households with high income), set the
#     component value to equal the maximum disparity ratio from the previous
#     step.
# • This approach captures the block groups with the greatest disparities by
#   setting those values to the minimum/maximum values, rather than replacing
#   those with the values for higher geographic levels.
DT[, numerator   := rowSums(.SD), .SDcols = sprintf("B19001_%03dE", 3:4)]
DT[, denominator := rowSums(.SD), .SDcols = sprintf("B19001_%03dE", 14:17)]
DT[, numeratorMOEsq   := rowSums(.SD^2), .SDcols = sprintf("B19001_%03dM", 3:4)]
DT[, denominatorMOEsq := rowSums(.SD^2), .SDcols = sprintf("B19001_%03dM", 14:17)]
DT[, component09E := numerator/denominator]
minmax_disparity_ratio <-
  DT[!is.na(component09E)][is.finite(component09E)][numerator > 0][denominator > 0][,
    .(min_disparity_ratio = min(component09E),
      max_disparity_ratio = max(component09E)),
    by = .(year)
  ]
DT <- merge(DT, minmax_disparity_ratio, all.x = TRUE, by = "year")
DT[numerator == 0,   component09E := min_disparity_ratio]
DT[denominator == 0, component09E := max_disparity_ratio]

# Step 2: Calculate the Margin of Error
DT[, component09M := 1/denominator * sqrt(numeratorMOEsq + (numerator/denominator)^2 * denominatorMOEsq)]
DT[numerator == 0 | denominator == 0, component09M := NA]

# 1. Build the raw disparity ratio
#      R = 100 * numerator / denominator
#   2. For rows with numerator > 0 and denominator > 0, compute MOE for R using the ratio formula:
#      MOE(R) = 100 * 1/X2 * sqrt( MOE(X1)^2 + (X1/X2)^2 * MOE(X2)^2 )
#      where:
#       - X1 = sum(B19001_002:004)
#       - X2 = sum(B19001_014:017)
#       - MOE(X1) and MOE(X2) are root-sum-of-squares of the component MOEs
#   3. For rows where numerator == 0 or denominator == 0, do the CMS min/max substitution on the ratio itself.
#      I would set the MOE for those rows to NA, mark them for exclusion from shrinkage-weight estimation, and not do geographic imputation.
#   4. Only take log(R) after that.
#      If you need a log-scale MOE later, derive it from the ratio-scale SE with a delta-method approximation:
#      SE(log R) ≈ SE(R) / R
#      and then MOE(log R) ≈ 1.645 * SE(log R)
#
#   That is the most defensible path because the exact CMS MOE rule is written for the ratio, not for log(ratio), and the min/max replacement logic also lives on the ratio scale.




# Step 3: Flag values that need replacement -- I don't think this is to be done
# here as the min/max values used above account for those issues.  Just set the
# flag_for_replacement to 0
DT[, flag_for_replacement := 0L]

# Step 4: Apply Shrinkage
# Step 5: Replace invalid values from step 3
DT <- steps_4_and_5(DT, "component09")

# Step 6: Standardize the component
DT[, component09 := scale(component09), by = .(year)]

# Steps 7, 8, and 9 are done in faircdi.R

# save this data to disk
data.table::fwrite(DT, file = "component09.csv")

################################################################################
#                                 End of File                                  #
################################################################################
