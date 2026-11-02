## 00_setup.R
## Download the packages, and sets the project paths 
## Files should be run in this order:  00_setup.R -> 01_cleaning.R -> 02_replicate.R

## Add all required packages
packages <- c("here", "dplyr", "readxl", "fixest", "ggplot2", "knitr")
for (p in packages) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p)
}
library(here)
library(dplyr)
library(readxl)
library(fixest)
library(ggplot2)
library(knitr)
library(tidyr)

## Use the here package
## i_am() tells here() where this file sits inside the project, so all paths below are
## relative to the project folder, not to a specific computer
here::i_am("code/00_setup.R")

# Data folders
raw_dir   <- here("data", "downloaded-data")       # data I downloaded myself
pkg_dir   <- here("data", "replication-package")   # Shover et al. (2019) Dataset in supplementary material S1
clean_dir <- here("data", "clean")                 # cleaned data created by 01_cleaning.R

# Result folders
tables_dir  <- here("results", "tables")
figures_dir <- here("results", "figures")

# Create folders if they do not already exist
dir.create(clean_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(figures_dir, showWarnings = FALSE, recursive = TRUE)


