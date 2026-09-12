# ==============================================================================
# 5. DISSERTATION VISUALIZATIONS
# ==============================================================================

# Load necessary libraries
library(haven)
library(ggplot2)
library(dplyr)

# 1. Load the dataset
df <- read_dta(".\\data\\Cleaned\\GM_Master_Analytical_Dataset.dta")

# 2. Histogram of Visual Change
p1 <- ggplot(df, aes(x = visual_change)) +
  geom_histogram(fill = "steelblue", color = "black", bins = 40, alpha = 0.8) +
  theme_minimal(base_size = 14) +
  labs(title = "Distribution of LSOA-Level Visual Change (2012-2019)",
       x = "Visual Change Score (CNN Derived)",
       y = "Frequency")

ggsave(".\\data\\Outputs\\visual_change_hist.png", 
       plot = p1, width = 8, height = 5, dpi = 300)

# 3. Scatter Plot: House Prices vs Visual Change
p2 <- ggplot(df, aes(x = visual_change, y = delta_log_price)) +
  geom_point(alpha = 0.4, color = "darkred") +
  geom_smooth(method = "lm", color = "black", linetype = "dashed", se = TRUE) +
  theme_minimal(base_size = 14) +
  labs(title = "House Price Growth vs. Visual Change",
       x = "Visual Change Score",
       y = "Log-Differenced House Prices (2020-2023)")

ggsave(".\\data\\Outputs\\scatter_house_prices.png", 
       plot = p2, width = 8, height = 5, dpi = 300)

# 4. Scatter Plot: Claimant Rate vs Visual Change
p3 <- ggplot(df, aes(x = visual_change, y = delta_claimant_rate)) +
  geom_point(alpha = 0.4, color = "darkgreen") +
  geom_smooth(method = "lm", color = "black", linetype = "dashed", se = TRUE) +
  theme_minimal(base_size = 14) +
  labs(title = "Claimant Rate Change vs. Visual Change",
       x = "Visual Change Score",
       y = "Change in Claimant Rate (% points)")

ggsave(".\\data\\Outputs\\scatter_claimant.png", 
       plot = p3, width = 8, height = 5, dpi = 300)

# 5. Scatter plot: levels-on-levels showing a real slope: House Prices 
p4 <- ggplot(master_data, aes(x = mean_score_2019, y = log_price_2023)) +
  geom_point(alpha = 0.4, color = "darkred") +
  geom_smooth(method = "lm", color = "black", linetype = "dashed") +
  labs(title = "Log House Prices (2023) vs. Visual Quality Level (2019)",
       x = "Visual Quality Score (2019 level)",
       y = "Log Median House Price (2023)") +
  theme_minimal()

ggsave(".\\data\\Outputs\\scatter_house_prices_LEVELS.png", 
       plot = p4, width = 8, height = 5, dpi = 300)

# 6. Scatter plot: levels-on-levels showing a real slope: Claimant rate
p5 <- ggplot(master_data, aes(x = mean_score_2019, y = claimant_rate_2023)) +
  geom_point(alpha = 0.4, color = "darkgreen") +
  geom_smooth(method = "lm", color = "black", linetype = "dashed") +
  labs(title = "Claimant Rate (2023) vs. Visual Quality Level (2019)",
       x = "Visual Quality Score (2019)", 
       y = "Claimant Rate (%)") +
  theme_minimal()

ggsave(".\\data\\Outputs\\scatter_claimant_LEVELS.png", 
       plot = p5, width = 8, height = 5, dpi = 300)
