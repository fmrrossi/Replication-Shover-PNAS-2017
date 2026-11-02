# Replication of Shover et al. (2019) and Bachhuber et al. (2014): medical cannabis laws and opioid overdose mortality

This repository replicates:

- **Shover, C. L., Davis, C. S., Gordon, S. C., & Humphreys, K. (2019).** "Association between medical cannabis laws and opioid overdose mortality has reversed over time." *Proceedings of the National Academy of Sciences*, 116(26), 12624–12626. https://doi.org/10.1073/pnas.1903434116
- **Bachhuber, M. A., Saloner, B., Cunningham, C. O., & Barry, C. L. (2014).** "Medical cannabis laws and opioid analgesic overdose mortality in the United States, 1999–2010." *JAMA Internal Medicine*, 174(10), 1668–1673.

Bachhuber et al. found that state medical cannabis laws were associated with 24.8% lower opioid analgesic overdose mortality over 1999–2010. Using the same model and data through 2017, Shover et al. found that the association reversed to +22.7%. I replicate Table 1 and Figure 1 of Shover et al. and Figures 1 and 2 of Bachhuber et al. I do this twice: with the authors' replication data, and with data I downloaded myself from publicly available sources

## Main results

- **Exact replication with the authors' data.** With the replication package (Dataset S1 of Shover et al.), all 17 point estimates and confidence intervals in Shover et al.'s Table 1 are reproduced exactly. Figure 1 is reproduced exactly too.
- **Replication with my own downloads.** The mortality data match the replication package on every state-year (922 of 922 death counts). The estimates are −21.4% for 1999–2010 (paper: −21.1%) and +25.0% for 1999–2017 (paper: +22.7%). The second gap is almost entirely the 14 New Hampshire and Tennessee state-years that were missing unemployment data  in the replication dataset and were therefore dropped in the analysis.
- **Bachhuber et al. (2014).** Figure 1 (mean mortality in states with and without a law) has the same levels and shape as the original. Figure 2 (effects by year since the law took effect) has the same pattern, with effects growing to about −35% by year 6+. The point estimates for years 1–5 are 1–7 points smaller. This is in line with small differences in estimates in the aggregate data as well.

## Repository structure

```
replication-Bachhuber-PNAS-2017/
├── README.md
├── code/
│   ├── 00_setup.R                  Loads packages and create folders
│   ├── 01_cleaning.R               Import, clean and merge the data
│   ├── 02_replicate_Shover.R       Shover et al. (2019) Table 1 and Figure 1
│   └── 03_replicate_Bachhuber.R    Bachhuber et al. (2014) Figures 1 and 2
├── data/
│   ├── downloaded-data/         Raw data I downloaded (CDC WONDER, BLS) + screenshot of the CDC WONDER query
│   ├── replication-package/     pnas.1903434116.sd01.csv (Shover et al. 2019, Dataset S1)
│   └── clean/                   analysis_data.csv, created by 01_cleaning.R
├── reference papers/            PDFs of the two papers
└── results/
    ├── tables/                  .csv and .tex tables
    └── figures/                 .png figures
```

## How to reproduce


1. Open R with the project folder (`replication-Bachhuber-PNAS-2017`) as the working directory, or open the folder as an RStudio project. All paths are built with `here()`, so nothing depends on where the folder sits on your computer.
2. Run the scripts in order:

```r
source("code/01_cleaning.R")          # also runs 00_setup.R
source("code/02_replicate_Shover.R")
source("code/03_additional_replicate_bachhuber_figures.R")
```

## Data sources and how I downloaded them

### 1. Opioid overdose mortality: CDC WONDER

File: `data/downloaded-data/Multiple Cause of Death, 1999-2020.xls`. Last downloaded on October 30, 2026. A screenshot of the query criteria is in `data/downloaded-data/CDC-Query.png`.

1. Go to https://wonder.cdc.gov/mcd.html and open **Multiple Cause of Death, 1999–2020** (https://wonder.cdc.gov/mcd-icd10.html). 
2. **Section 1 (Organize table layout):** group results by **State** and then **Year**. Under measures, tick **Age Adjusted Rate** and its **95% Confidence Interval**.
3. **Sections 2–5:** leave all states, all years, and all ages, sexes, races/ethnicities selected. I downloaded 1999–2020.
4. **Section 6 (Select underlying cause of death):** choose "UCD - ICD-10 Codes" and select the drug-poisoning codes of any intent:
   - X40–X44 (unintentional)
   - X60–X64 (suicide)
   - Y10–Y14 (undetermined intent)
5. **Section 7 (Select multiple cause of death):** enter **T40.2, T40.3, T40.4** in the "any of these items" box. These are other opioids such as oxycodone and hydrocodone, methadone, and other synthetic narcotics such as fentanyl. 
6. Send the request and export the results.
7. **Rates for 10–19 deaths:** WONDER suppresses counts of 1–9 deaths. For 10–19 deaths it reports the confidence interval but flags the rate as "Unreliable" and does not show it. Following Shover et al., `01_cleaning.R` uses the midpoint of the 95% confidence interval as the rate in those cases.

### 2. Unemployment: Bureau of Labor Statistics

File: `data/downloaded-data/staadata.xlsx`. Source: BLS Local Area Unemployment Statistics, "Employment status of the civilian noninstitutional population by state, annual averages, 1976 to 2025", at https://www.bls.gov/lau/tables.htm#stateaa. I use column 10, the annual average unemployment rate, for the 50 states and 1999–2017.

### 3. Replication package

File: `data/replication-package/pnas.1903434116.sd01.csv`. This is Dataset S1 of Shover et al. (2019), downloaded from the PNAS supplementary materials page of the article on October 26, 2026. It contains the outcome, the cannabis policy variables, the opioid policy variables and unemployment for 50 states, 1999–2017.

**The policy variables (cannabis and opioid laws) are taken from this file.** Only the outcome and unemployment are rebuilt from public sources. Bachhuber et al. coded the opioid laws from the National Alliance for Model State Drug Laws and the CDC Public Health Law Program. Shover et al. extended them and added the cannabis law categories.

## Variables

### Replication package (`pnas.1903434116.sd01.csv`), 947 state-years

The panel has 50 states × 19 years = 950 rows minus 3, because North Dakota has no rows for 2011–2013. DC is not included.

| Variable | Description | Notes |
|---|---|---|
| `state`, `Year` | State name and calendar year, 1999–2017 | |
| `Deaths` | Opioid analgesic overdose deaths (definition in data source 1) | Missing in 25 state-years with 1–9 deaths (suppressed) |
| `Population` | Resident population used by CDC WONDER | |
| `Crude_Rate` | Deaths per 100,000 population | Missing when suppressed or unreliable (fewer than 20 deaths) |
| `Age_Adjusted_Rate` | Death rate per 100,000, age-adjusted to the 2000 U.S. standard population | Missing in 57 state-years (suppressed or unreliable) |
| `Age_Adjusted_Rate_Lower_95__Conf`, `..._Upper_95__Conf` | 95% CI of the age-adjusted rate | Missing only when suppressed (25) |
| `Crude_Rate_Lower_95__Confidence`, `..._Upper_95__Confidence`, `Crude_Rate_Standard_Error`, `Age_Adjusted_Rate_Standard_Error` | CIs and standard errors of the crude rate, and standard error of the age-adjusted rate | Only filled for 2011–2017 |
| `ln_age_mort_rate` | **Outcome:** log of the age-adjusted rate. For the 32 "unreliable" state-years (10–19 deaths), the rate is the midpoint of the 95% CI | Missing in the 25 suppressed state-years |
| `ln_crude_mort_rate` | Log of the crude rate, computed as log(Deaths / Population × 100,000) when the published rate is missing | Not used in the models |
| `Medical_Cannabis_Law` | **Treatment:** any medical cannabis law in force, including low-THC-only laws. 0 before the law; in the adoption year, the share of the year the law was in force (e.g. 0.5 for a law effective July 1); 1 afterwards. It never switches off | |
| `comprehensive_medical_cannabis` | Medical cannabis law with no restriction on THC content, in a state without a recreational law | Same fractional coding |
| `low_thc` | Medical law restricted to low-THC / high-cannabidiol (CBD) products only | Same fractional coding |
| `recreational_cannabis_law` | Recreational (adult-use) law in force, which comes on top of a medical law | Same fractional coding |
| `rxdmp_original` | Prescription drug monitoring program in operation: a state database of controlled-substance prescriptions | Coding of Bachhuber et al. (National Alliance for Model State Drug Laws); fractional in 13 start years |
| `rxid_original` | Law requiring or allowing pharmacists to ask for patient identification before dispensing | Coding of Bachhuber et al. (CDC Public Health Law Program) |
| `pmlaw_original` | Increased state oversight of pain management clinics ("pill mill" laws) | Coding of Bachhuber et al. (CDC Public Health Law Program) |
| `rxdmp_update`, `rxid_update`, `pmlaw_update` | The same three laws as recoded by Shover et al. after a review of the legal literature | Not used in Table 1. Differ from the original coding in 55, 104 and 8 state-years |
| `unemployment` | Annual average state unemployment rate (%), BLS | Missing for New Hampshire and Tennessee in 2011–2017 (14 state-years). Stored at low precision (8.3 appears as 8.298828), so round to one decimal |

The three categories add up to the overall law, so the expanded model's three treatment variables are mutually exclusive. 
Treatment is not constructed as a binary variable, but rather it is given the share of the year for which it has been active. If for instance a law was passed on June 1, 2010 in state s, then treatment is 7/12. 
In the year a state moves from one category to another, the shares are split by date. For example, Florida 2016 is 0.50 low-THC and 0.50 comprehensive.

### Analysis dataset (`data/clean/analysis_data.csv`), created by `01_cleaning.R`

The replication package is the base (947 state-years).

| Variable | Description |
|---|---|
| `state`, `Year` | As above |
| `deaths_rep`, `pop_rep` | `Deaths`, `Population` from the package |
| `aar_rep`, `ln_rate_rep` | Age-adjusted rate used in the paper, `exp(ln_age_mort_rate)`, and its log |
| `unemp_rep` | Package unemployment, rounded to one decimal |
| `Medical_Cannabis_Law`, `comprehensive_medical_cannabis`, `low_thc`, `recreational_cannabis_law`, `rxdmp_original`, `rxid_original`, `pmlaw_original` | Policy variables from the package (see above) |
| `deaths_dl`, `pop_dl` | Deaths and population from my CDC WONDER download |
| `aar_lo`, `aar_hi` | 95% CI of the age-adjusted rate, CDC WONDER |
| `unreliable` | TRUE if WONDER flags the rate as unreliable (10–19 deaths) |
| `aar_dl`, `ln_rate_dl` | Age-adjusted rate from my download (CI midpoint when unreliable) and its log |
| `unemp_dl` | Unemployment rate from my BLS download |
| `diff_deaths`, `diff_pop`, `diff_rate`, `diff_unemp` | Downloaded minus package value |

## Models

States are indexed by $s$ (50 states) and years by $t$. $Y_{st}$ is the age-adjusted opioid analgesic overdose death rate per 100,000. $\alpha_s$ and $\lambda_t$ are state and year fixed effects.

**Main model.** This is Shover et al.'s Table 1, Replication and Extension columns, and the main model of Bachhuber et al.:

$$
\ln Y_{st} = \alpha_s + \lambda_t + \beta\,\mathrm{MCL}_{st} + \mathbf{X}_{st}'\gamma + \varepsilon_{st}
$$

-  $\mathrm{MCL}_{st}$ is the treatment variable, and \mathrm{X} is a vector of the four covariates (PDMP, RxID, PainClinic and Unemp)
- The model is estimated by OLS on the log rate
- Standard errors are clustered by state
- Effects are reported as percent changes, computed as $100\,(e^{\hat\beta}-1)$, with corresponding confidence intervals calculated as $100\,(e^{\hat\beta \pm 1.96\,\widehat{se}}-1)$.

**Expanded model.** This is Shover et al.'s Table 1, last column. The overall law is split into its three mutually exclusive categories:

$$
\ln Y_{st} = \alpha_s + \lambda_t + \mathbf{X}_{st}'\gamma + \beta\,\mathrm{REC}_{st} + \beta\,\mathrm{COMP}_{st} + \beta\,\mathrm{LOW}_{st} +  \varepsilon_{st}, \qquad t = 1999,\dots,2017,
$$

- The treatment variable is substituted by three mutually exclusive more granular variable capturing the intensities of different cannabis legislation. 

**Shover et al. Figure 1.** The main model is re-estimated for every end year $T = 2002, \dots, 2017$, and $100\,(e^{\hat\beta_T}-1)$ is plotted with its 95% CI against $T$.
<!--
**Bachhuber et al. Figure 1** is descriptive: the unweighted mean of $Y_{st}$ across states, in each year 1999–2010, separately for states with $\mathrm{MCL}_{st} > 0$ and states with $\mathrm{MCL}_{st} = 0$.

**Bachhuber et al. Figure 2 (effect by year since implementation).** Let $g_s$ be the year state $s$'s law took effect:

$$
\ln Y_{st} = \alpha_s + \lambda_t + \delta_0\,\mathrm{MCL}_{st}\,\mathbf{1}\{t = g_s\} + \sum_{k=1}^{5} \delta_k\,\mathbf{1}\{t - g_s = k\} + \delta_{6}\,\mathbf{1}\{t - g_s \ge 6\} + \mathbf{X}_{st}'\gamma + \varepsilon_{st}, \qquad t = 1999,\dots,2010.
$$

The figure plots $100\,(e^{\hat\delta_k}-1)$ for $k = 1, \dots, 6$. Bachhuber et al. do not spell out every coding detail, so I made these choices (also documented in `03_bachhuber_figures.R`):
- Years since the law = $t - g_s$. This matches their example of California's 1996 law being coded 3 in 1999.
- The adoption year enters with its fractional share and is not plotted.
- Years 6 and later are pooled.
- Laws effective before 1999 are dated California 1996, Oregon 1998 and Washington 1998, as in Bachhuber et al.
-->
### Interpretation: a two-way fixed effects difference-in-differences

The main model is a two-way fixed effects (TWFE). With a single adoption date, a 0/1 treatment and no covariates, $\hat\beta$ equals the textbook 2×2 DiD. Its causal interpretation rests on **parallel trends in logs**: without the law, adopting and non-adopting states would have had the same *percentage* change in overdose mortality.

Two features of the papers' design make $\hat\beta$ harder to interpret:

1. **Mid-year adoption is coded as a fraction.** A law effective on July 1 contributes 0.5 in its first year. $\hat\beta$ is therefore the effect of moving from 0 to 1, assuming the first-year effect is proportional to the share of the year the law was in force. It is not the average effect in the adoption year. That assumption is untestable, and it mixes "dose" and timing within the same coefficient.
2. **Staggered adoption.** States adopt between 1996 and 2017, so $\hat\beta$ is a weighted average of all possible 2×2 DiD comparisons (Goodman-Bacon, 2021). Some of these use already-treated states as controls for later adopters. If effects differ across states or grow over time, some weights can be negative (de Chaisemartin & D'Haultfœuille, 2020), and $\hat\beta$ need not equal any average effect of the law. This matters especially for the 1999–2017 estimate: more than half of the 45 states with a law by 2017 adopted in 2014–2017, mostly low-THC-only laws, at the same time as the rise of illicit fentanyl.

States treated throughout the sample (California, Oregon, Washington) never change status. They help identify the year effects but contribute no before/after comparison of their own.

## Differences between the downloaded data and the replication package

`01_cleaning.R` compares the two sources for every state-year and writes the comparison to `results/tables/discrepancies_by_year.*` and `results/figures/discrepancies.png`.

- **Deaths:** identical in all 922 state-years available in both.
- **Population and rates:** identical except in 2001–2009, where CDC WONDER now uses revised intercensal population estimates instead of the postcensal ones available when the papers were written. Age-adjusted rates differ by at most 0.4 per 100,000.
- **Missing state-years:** WONDER does not export state-years with suppressed counts when "Show Suppressed" is off, so 25 state-years are missing in both sources.
- **Unemployment:** BLS revises LAUS estimates every year (annual benchmarking, a 2015 model redesign, population control updates). The values in the package are an older release; Bachhuber et al. accessed the data on February 5, 2014. About 40% of state-years match exactly, the mean absolute gap is 0.06–0.25 points, and the gaps are largest in 2009–2010. Holding the sample fixed, using today's BLS values changes the 1999–2017 estimate from 22.7% to 22.6%.
- **New Hampshire and Tennessee:** the package has no unemployment rate for either state in 2011–2017, although BLS publishes them, so these 14 state-years drop out of the paper's regressions. Adding them back with BLS data raises the 1999–2017 estimate to about 25%.

## Outputs

| File | Content |
|---|---|
| `results/tables/table1_replication.tex` | Shover et al. Table 1, replicated with the package data, in the paper's layout |
| `results/tables/table1_comparison.{csv,tex}` | Table 1 as reported vs. replicated with the package data vs. replicated with my downloaded data |
| `results/tables/table1_all_estimates.csv` | All coefficients, both data versions |
| `results/figures/figure1_replication.png`, `results/tables/figure1_estimates.csv` | Shover et al. Figure 1 |
| `results/figures/figure1_package_vs_downloaded.png` | Figure 1 with the package data vs. my downloaded data |
| `results/figures/bachhuber_figure1.png`, `results/tables/bachhuber_figure1_means.csv` | Bachhuber et al. Figure 1 |
| `results/figures/bachhuber_figure2.png`, `results/tables/bachhuber_figure2_estimates.{csv,tex}` | Bachhuber et al. Figure 2, with the published estimates for comparison |
| `results/tables/discrepancies_by_year.{csv,tex}`, `results/tables/discrepancies_state_year.csv`, `results/figures/discrepancies.png` | Downloaded data vs. package, by year and by state-year |

## References

- Bachhuber, M. A., Saloner, B., Cunningham, C. O., & Barry, C. L. (2014). Medical cannabis laws and opioid analgesic overdose mortality in the United States, 1999–2010. *JAMA Internal Medicine*, 174(10), 1668–1673.
- de Chaisemartin, C., & D'Haultfœuille, X. (2020). Two-way fixed effects estimators with heterogeneous treatment effects. *American Economic Review*, 110(9), 2964–2996.
- Goodman-Bacon, A. (2021). Difference-in-differences with variation in treatment timing. *Journal of Econometrics*, 225(2), 254–277.
- Shover, C. L., Davis, C. S., Gordon, S. C., & Humphreys, K. (2019). Association between medical cannabis laws and opioid overdose mortality has reversed over time. *Proceedings of the National Academy of Sciences*, 116(26), 12624–12626.
- Centers for Disease Control and Prevention, National Center for Health Statistics. Multiple Cause of Death 1999–2020 on CDC WONDER Online Database. https://wonder.cdc.gov/mcd-icd10.html. Accessed October 30, 2026.
- U.S. Bureau of Labor Statistics. Local Area Unemployment Statistics, annual average state series. https://www.bls.gov/lau/tables.htm#stateaa.

