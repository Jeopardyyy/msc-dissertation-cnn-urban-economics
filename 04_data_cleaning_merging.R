# Done with all other stages. CNN pipeline is complete.
# I now have lsoa_scores.csv: 1627 rows, one per LSOA
# columns: lsoa_code, mean_score_2012, mean_score_2019, visual_change

# First, I need to clean and structure the data ive downloaded

# Through this script, I'll merge everything into one master analytical dataset
# for Stata

# Libraries
library(readxl)
library(dplyr)
library(stringr)
library(readr)
library(haven)

# Define Base Path
base_path <- ".\\data\\Raw"

#===================================================================

# 1. House Prices - Δ log(median price) from 2020 to 2023
# Source: ONS House Price Statistics for Small Areas (HPSSA Dataset 46)
# This dataset contains median house prices for every LSOA in England & Wales
# across multiple time periods in one Excel file.

#====================================================================

hp_file <- paste0(base_path, "HPSSA Dataset 46 - Median price paid for residential properties by LSOA.xls")
prices  <- read_excel(hp_file, sheet = "1a", skip = 5)
# skip = 5 because the ONS file has 5 rows of title/header metadata before
# the actual column names row 

# Filtering to the 10 GM metropolitan boroughs only
gm_lsoas <- c("Bolton", "Bury", "Manchester", "Oldham", "Rochdale", 
            "Salford", "Stockport", "Tameside", "Trafford", "Wigan")

gm_prices <- prices %>%
  filter(`Local authority name` %in% gm_lsoas) %>%  #Keep only GM rows
  select(
    lsoa_code = `LSOA code`,   #Rename to match my key across all datasets
    price_2020 = `Year ending Mar 2020`,  # Baseline price
    price_2023 = `Year ending Mar 2023`   #End price
  ) %>%
  mutate(
    # Convert to numeric (coercing ":" or missing to NA)
    price_2020 = as.numeric(price_2020),
    price_2023 = as.numeric(price_2023),
    # Log difference = percentage change in house prices (approx)
    # Using logs is standard in housing economics because house price distributions
    # are right-skewed - logging makes the outcome variable more normally distributed
    delta_log_price = log(price_2023) - log(price_2020)
  )

write_csv(gm_prices, paste0(base_path, "GM_house_prices_2020_2023.csv"))

# ==============================================================================
# 2. Claimant Rate — Δ claimant rate (percentage points) 2020 to 2023
# Source: NOMIS (claimant counts) + NOMIS (both years' population estimates)
# I compute the rate (claimants as % of working age population) rather than
# raw counts because LSOAs vary in population size - rates are comparable.
# ==============================================================================

claim_file  <- paste0(base_path, "GM_Claimcount_2020_2023.csv")
pop_file    <- paste0(base_path, "popest_gm_2020_2023.csv")
lookup_file <- paste0(base_path, "lookup_11_21.csv")

# Load claimant counts - already on 2011 LSOA boundaries from NOMIS
# skip = 8 skips NOMIS metadata rows before the data begins
# col_names assigns my own column names since the original headers are messy
claim_raw <- read_csv(claim_file, skip = 8, col_names = c("raw_area", "count_2020", "count_2023")) %>%
  filter(str_detect(raw_area, "^E01")) %>% # Keep only LSOA rows (codes start with E01)
  mutate(
    # str_extract pulls the 9 character LSOA code from the beginning of the area string
    LSOA11CD = str_extract(raw_area, "^E\\d{8}"),
    # (?<=:\\s) is a regex lookbehind - extracts the word after ": " in the area name
    # This gives me the borough name (Bolton, Bury etc.) for fixed effects later
    local_authority = str_extract(raw_area, "(?<=:\\s)[A-Za-z]+"),
    count_2020 = as.numeric(count_2020),
    count_2023 = as.numeric(count_2023)
  )

# Load population estimates - these come on 2021 LSOA boundaries from NOMIS
# because ONS uses different boundary vintages for different datasets.
# I need to crosswalk these back to 2011 boundaries to match claimant data.
popest_raw <- read_csv(pop_file, skip = 6, col_names = c("raw_area", "pop_2020", "pop_2023")) %>%
  filter(str_detect(raw_area, "^E01")) %>%
  mutate(
    LSOA21CD = str_extract(raw_area, "^E\\d{8}"),# 2021 LSOA code
    pop_2020 = as.numeric(pop_2020),
    pop_2023 = as.numeric(pop_2023)
  )

# Load the ONS official lookup table that maps 2021 LSOA codes to 2011 equivalents.
# This handles cases where LSOA boundaries were redrawn between censuses -
# some 2021 LSOAs correspond to split or merged 2011 LSOAs.
lookup_11_21 <- read_csv(lookup_file) %>% select(LSOA11CD, LSOA21CD)

# Join population data to lookup, then aggregate by 2011 LSOA code.
# group_by + summarise with sum() handles split LSOAs - if one 2011 LSOA
# was split into two 2021 LSOAs, I add their populations back together.
popest_cw <- popest_raw %>%
  inner_join(lookup_11_21, by = "LSOA21CD") %>%
  group_by(LSOA11CD) %>%
  summarise(
    pop_2020 = sum(pop_2020, na.rm = TRUE),
    pop_2023 = sum(pop_2023, na.rm = TRUE),
    .groups = 'drop'
  )

# Calculating claimant rates and the outcome variable.
# Rate = (claimants / working age population) × 100 -> gives percentage points.
# delta_claimant_rate = the change in that percentage between 2020 and 2023.
# A positive value means unemployment benefit claiming went up in that LSOA.
claim_rate <- claim_raw %>%
  inner_join(popest_cw, by = "LSOA11CD") %>%
  mutate(
    claimant_rate_2020 = (count_2020 / pop_2020) * 100,
    claimant_rate_2023 = (count_2023 / pop_2023) * 100,
    # Calculate Absolute Percentage Point Change
    delta_claimant_rate = claimant_rate_2023 - claimant_rate_2020
  ) %>%
  select(lsoa_code = LSOA11CD, local_authority, claimant_rate_2020, claimant_rate_2023, delta_claimant_rate)

write_csv(claim_rate, paste0(base_path, "GM_claimant_rate_2020_2023.csv"))

# =====================================================================

# 3. CENSUS CONTROLS

# Source: NOMIS Census 2011: Table KS608EW to KS610EW and Table KS402EW
# I use 2011 Census because it's the closest available baseline to my 2012
# Street View images, and predates any changes my visual change variable captures.


#Cleaning KS608EW to KS610EW(% in higher managerial/professional occupations)
# and KS402EW(% owner occupied housing)

# ==============================================================================
# 3.A Clean Occupation Data (Table KS608EW to KS610EW)
# ==============================================================================
# Read the file, skipping the first 9 lines of Nomis metadata headers
occ_raw <- read_csv(paste0(base_path, "KS608EW_to_KS610EW.csv"), skip = 9, 
                    col_names = c("raw_area", "managers", "professionals")) %>%
  # Keeping only LSOA rows (starts with E01)
  filter(str_detect(raw_area, "^E01")) %>%
  mutate(
    # Extract the 9-character LSOA code
    lsoa_code = str_extract(raw_area, "^E\\d{8}"),
    # Extract the Local Authority name for easy tracking
    local_authority = str_extract(raw_area, "(?<=:\\s)[A-Za-z]+"),
    # Convert data to numeric
    managers = as.numeric(managers),
    professionals = as.numeric(professionals),
    # Combine the two higher-tier occupations into final % professional metric
    pct_professional = managers + professionals 
  ) %>%
  # Selecting only the columns needed for final merge
  select(lsoa_code, local_authority, managers, professionals, pct_professional)

# Exporting the final dataset
write_csv(occ_raw, "census_occupation.csv")

# ==============================================================================
# 3.B Clean Tenure Data (Table KS402EW)
# Owner occupancy rate is a standard housing market control - areas with higher
# owner occupancy tend to have more stable and higher house prices.
# ==============================================================================
# Skipping the metadata headers
tenure_raw <- read_csv(paste0(base_path, "KS402EW.csv"), skip = 9, 
                       col_names = c("raw_area", "owned_outright", "owned_mortgage")) %>%
  filter(str_detect(raw_area, "^E01")) %>%
  mutate(
    lsoa_code = str_extract(raw_area, "^E\\d{8}"),
    local_authority = str_extract(raw_area, "(?<=:\\s)[A-Za-z]+"),
    owned_outright = as.numeric(owned_outright),
    owned_mortgage = as.numeric(owned_mortgage),
    # I combine outright owners and mortgaged owners because both represent
    # owner occupier households - the distinction doesn't matter for my purposes.
    pct_owner_occupier = owned_outright + owned_mortgage 
  ) %>%
  select(lsoa_code, local_authority, owned_outright, owned_mortgage, pct_owner_occupier)

# Exporting the final dataset
write_csv(tenure_raw, "census_tenure.csv")


#=====================================================================

# 4. Index of Multiple Deprivation (IMD) 2015 - Also baseline control
# Source: Ministry of Housing, Communities & Local Government
# I use IMD 2015 rather than IMD 2019 because it predates my visual change
# measurement window (2012-2019), so it captures baseline deprivation rather
# than potentially being endogenous to my outcome period.

# ==============================================================================
# Reading the IMD data from the specific sheet
imd_raw <- read_excel(paste0(base_path, "IMD2015.xlsx"), sheet = "ID2015 Scores")

# Define GM local authorities
gm_lsoas <- c("Bolton", "Bury", "Manchester", "Oldham", "Rochdale", 
            "Salford", "Stockport", "Tameside", "Trafford", "Wigan")

# Filter and clean the dataset
imd_gm <- imd_raw %>%
  # Filter for Greater Manchester boundaries
  filter(`Local Authority District name (2013)` %in% gm_lsoas) %>%
  # Selecting the essential columns and renaming them to match master panel keys
  select(
    lsoa_code = `LSOA code (2011)`,
    local_authority = `Local Authority District name (2013)`,
    imd_score = `Index of Multiple Deprivation (IMD) Score`,
    imd_income_score = `Income Score (rate)` # Income domain - kept as robustness variable
  )

# Exporting the final dataset
write.csv(imd_gm, "GM_IMD_2015.csv", row.names = FALSE)
# row.names = FALSE prevents R from adding an unwanted row number column


# ========================================================================= 

# 5. DATA MERGING - MASTER ANALYTICAL DATASET AND EXPORTING TO STATA
# Merging all datasets on lsoa_code

# ==========================================================================

Final_path <- ".\\data\\Cleaned"

# Loading the CNN-derived perception scores - the output of 03_CNN_SCORING.ipynb
scores <- read_csv(".\\data\\Outputs\\Scores\\lsoa_scores2.csv")

# Drop LSOAs missing a valid visual_change score (i.e. missing coverage in
# either 2012 or 2019 after the corrected pano-based download). This is a
# known, documented consequence of historical Street View coverage gaps -
# see data section for coverage statistics (1,230/1,673 LSOAs retained
# pre-merge; final N after merging with outcome/control data below).
n_before <- nrow(scores)
scores <- scores %>% filter(!is.na(visual_change))
n_after <- nrow(scores)
cat("LSOAs dropped due to missing visual_change:", n_before - n_after, "\n")
cat("LSOAs retained with valid visual_change:", n_after, "\n")


# Building the master panel using a chain of inner_joins on lsoa_code.
# inner_join keeps only rows where the LSOA code exists in BOTH datasets -
# this automatically drops any LSOAs that are missing from any data source.
# I select only the columns I need from each dataset before joining to avoid
# duplicate column name conflicts (eg., local_authority appearing multiple times).
master_data <- scores %>%
  select(lsoa_code, mean_score_2019, visual_change)%>%
  # Join outcome variable 1: log house price change
  inner_join(gm_prices %>% select(lsoa_code, price_2023, delta_log_price), by = "lsoa_code") %>%
  mutate(log_price_2023 = log(price_2023)) %>%
  # Join outcome variable 2: claimant rate + the change + local_authority for fixed effects
  inner_join(claim_rate %>% select(lsoa_code, local_authority, claimant_rate_2023, delta_claimant_rate), by = "lsoa_code") %>%
  
  # Join baseline deprivation control - I drop local_authority here to avoid
  # a duplicate column since I already have it from claim_rate above
  inner_join(imd_gm %>% select(lsoa_code, imd_score, imd_income_score), by = "lsoa_code") %>%
  
  # Join socioeconomic composition control from Census 2011
  inner_join(occ_raw %>% select(lsoa_code, pct_professional), by = "lsoa_code") %>%
  
  # Join housing tenure control from Census 2011
  inner_join(tenure_raw %>% select(lsoa_code, pct_owner_occupier), by = "lsoa_code")

# Exporting as a .dta file for Stata
# haven::write_dta handles the conversion from R's data types to Stata's.
# All subsequent regression analysis (OLS, robustness checks, fixed effects)
# is done in Stata rather than R because Stata's cluster-robust SE implementation
# and output formatting is more standard in economics research.

cat("\nFinal master dataset N:", nrow(master_data), "LSOAs\n")

write_dta(master_data, paste0(Final_path, "GM_Master_Analytical_Dataset.dta"))
print("Master dataset successfully merged and exported for Stata!")

#################### Checking something

master_data %>% filter(claimant_rate_2023 > 15) %>% select(lsoa_code, claimant_rate_2023, mean_score_2019)

# Check how many rows have missing house price data specifically
sum(is.na(master_data$delta_log_price))
sum(is.na(master_data$delta_claimant_rate))

# See the actual gap
nrow(master_data)  # should be 1,325
nrow(master_data %>% filter(!is.na(delta_log_price)))  # should be 1,246

############ MAGNITUDE CALC #############

mean_price_2023 <- mean(master_data$price_2023, na.rm = TRUE)
mean_price_2023

mean_claim_2023 <- mean(master_data$claimant_rate_2023, na.rm = TRUE)
mean_claim_2023
# If beta_std is my standardized coefficient on log(price), a 1SD increase
# in visual quality is associated with (exp(beta_std) - 1) * 100 % change in price