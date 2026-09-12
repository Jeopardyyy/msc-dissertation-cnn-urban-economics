* =========================================================
* GM Street View Visual Quality — Regression Analysis
* =========================================================

use "GM_Master_Analytical_Dataset.dta", clear

* 1. PREPARATION
encode local_authority, gen(la_id)
egen visual_change_std = std(visual_change)
egen visual_level_std = std(mean_score_2019)

* 2. HOUSE PRICE REGRESSIONS (long-difference)
regress delta_log_price imd_score pct_professional pct_owner_occupier, vce(cluster la_id)
regress delta_log_price visual_change, vce(cluster la_id)
regress delta_log_price visual_change imd_score pct_professional pct_owner_occupier, vce(cluster la_id)
regress delta_log_price visual_change imd_score pct_professional pct_owner_occupier i.la_id, robust
regress delta_log_price visual_change_std imd_score pct_professional pct_owner_occupier, robust

* 3. CLAIMANT RATE REGRESSIONS (long-difference)
regress delta_claimant_rate imd_score pct_professional pct_owner_occupier, vce(cluster la_id)
regress delta_claimant_rate visual_change, vce(cluster la_id)
regress delta_claimant_rate visual_change imd_score pct_professional pct_owner_occupier, vce(cluster la_id)
regress delta_claimant_rate visual_change imd_score pct_professional pct_owner_occupier i.la_id, robust
regress delta_claimant_rate visual_change_std imd_score pct_professional pct_owner_occupier, robust

* 4. CROSS-SECTIONAL HOUSE PRICE REGRESSIONS (levels)
regress log_price_2023 imd_score pct_professional pct_owner_occupier, vce(cluster la_id)
regress log_price_2023 mean_score_2019, vce(cluster la_id)
regress log_price_2023 mean_score_2019 imd_score pct_professional pct_owner_occupier, vce(cluster la_id)
regress log_price_2023 mean_score_2019 imd_score pct_professional pct_owner_occupier i.la_id, robust
regress log_price_2023 visual_level_std imd_score pct_professional pct_owner_occupier, robust

* 5. CROSS-SECTIONAL CLAIMANT RATE REGRESSIONS (levels)
regress claimant_rate_2023 imd_score pct_professional pct_owner_occupier, vce(cluster la_id)
regress claimant_rate_2023 mean_score_2019, vce(cluster la_id)
regress claimant_rate_2023 mean_score_2019 imd_score pct_professional pct_owner_occupier, vce(cluster la_id)
regress claimant_rate_2023 mean_score_2019 imd_score pct_professional pct_owner_occupier i.la_id, robust
regress claimant_rate_2023 visual_level_std imd_score pct_professional pct_owner_occupier, robust

* 6. SUMMARY STATISTICS
summarize log_price_2023 claimant_rate_2023 delta_log_price delta_claimant_rate mean_score_2019 visual_change imd_score pct_professional pct_owner_occupier