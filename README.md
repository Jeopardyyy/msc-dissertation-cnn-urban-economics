# Seeing Decline Before It Shows: Do CNN-Derived Visual Changes in Google Street View Predict Local Economic Outcomes? Evidence from Greater Manchester
**MSc Economics and Data Science Dissertation | University of Warwick**

## Overview
This repository contains the complete codebase for my master's thesis. The project bridges computer vision and urban economics by training a Siamese ResNet-18 CNN on the Place Pulse 2.0 dataset to measure street-level visual quality from Google Street View imagery. I then use spatial econometrics to test whether these algorithmically-derived visual changes predict house price and claimant rate movements across 1,325 Lower Layer Super Output Areas (LSOAs) in Greater Manchester.

## Pipeline Order
If you wish to follow the methodology, the scripts should be run in this order:
1. `01_CNN_Training_on_PP2.ipynb` - Builds and trains the Siamese CNN.
2. `02_streetview_download.ipynb` - Generates spatial points and downloads Greater Manchester's historical Street View imagery via panorama ID matching.
3. `03_CNN_SCORING.ipynb` - Scores the images using the trained model to produce LSOA-level visual quality indices.
4. `04_data_cleaning_merging.R` - Cleans and merges the visual scores with ONS/NOMIS administrative data.
5. `05_Figures.R` - Generates the distribution histograms and scatter plots.
6. `Regressions.do` - The Stata do-file running all cross-sectional and long-difference OLS specifications.

## Data Availability & Sourcing
The human pairwise comparison data and corresponding images used to train the CNN are based on the MIT Place Pulse 2.0 dataset (Dubey et al., 2016). Since the original MIT servers are frequently inaccessible, the training data (named "final_data.csv" in step 1 of the pipeline) for this project was sourced from the open-source mirror provided by the Chinese Academy of Sciences (Min et al., 2020), available [here](https://github.com/minweiqing/Multi-Task-Deep-Relative-Attribute-Learning-for-Visual-Urban-Perception).

## Requirements
- Python 3.x with PyTorch, requests, osmnx, streetview
- R with tidyverse, haven
- Stata 16+

*Note: Raw Street View images and administrative data files are not included in this repository due to GitHub file size constraints. Scripts assume data is placed in a local `.\\data` directory
(update paths as needed).*
