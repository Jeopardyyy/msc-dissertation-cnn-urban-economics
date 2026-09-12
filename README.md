# msc-dissertation-cnn-urban-economics
CNN-derived visual quality measures Local Economic Outcomes: Greater Manchester - MSc dissertation

MSc Economics and Data Science dissertation, University of Warwick.

## Overview
This project trains a Siamese ResNet-18 CNN on the Place Pulse 2.0 dataset to
measure street-level visual quality from Google Street View imagery, and tests
whether this measure predicts house prices and claimant rates across Greater
Manchester LSOAs.

## Pipeline order
1. `01_CNN_Training_on_PP2.ipynb` - trains the Siamese ResNet-18 CNN on Place Pulse 2.0
   pairwise comparisons
2. `02_streetview_download.ipynb` - downloads Greater Manchester's historical
   Street View imagery via panorama ID matching (see dissertation Section 3.2)
3. `03_CNN_SCORING.ipynb` - scores Greater Manchester images using the
   trained model to produce LSOA-level visual quality indices
4. `04_data_cleaning_merging.R` - merges visual scores with ONS/NOMIS
   administrative data into the master analytical dataset
5. `05_Figures.R` - generates the scatter plots and distribution histogram
   reported in the dissertation
6. `Regressions.do` - runs the cross-sectional and long-difference OLS
   specifications reported in Tables 1-5

## Requirements
- Python 3.x with PyTorch, requests, osmnx, streetview
- R with tidyverse, haven
- Stata 17+

## Note
Raw imagery and administrative data files are not included due to size and
licensing; scripts assume data is placed in a local `data/` directory
(update paths as needed)
