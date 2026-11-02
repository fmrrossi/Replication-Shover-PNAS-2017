### 01_cleaning.R
### Import the downloaded data, clean it, merge it with the replication package and compare the two.
### Creates data/clean/analysis_data.csv plus discrepancy and summary-statistics tables/figures.

source(here::here("code", "00_setup.R"))

### Import CDC Wonder ("data/downloaded-data/Multiple Cause of Death, 1999-2017.xls")
# Query for the download is : UCD - ICD-10 codes X40-X44, X60-X64, Y10-Y14 (drug poisoning, any intent) and
#        MCD - ICD-10 codes T40.2, T40.3, T40.4 (opioid analgesics); grouped by State and Year.
#        The file covers 1999-2020; the merge below keeps only the package's state-years (1999-2017).

wonder <- read.delim(here("data", "downloaded-data", "Multiple Cause of Death, 1999-2020.xls"), colClasses = "character", check.names = FALSE)
wonder <- wonder[!is.na(wonder$State) & wonder$State != "", ]
wonder <- wonder[wonder$State != "District of Columbia", ]     # the paper excludes DC
wonder <- wonder[!wonder$Year %in% c(2018, 2019, 2020), ]      # also limit to 1999-2017 for this analysis

wonder <- data.frame(
  state        = wonder$State,
  Year         = as.integer(wonder$Year),
  deaths_dl    = suppressWarnings(as.numeric(wonder$Deaths)),
  pop_dl       = suppressWarnings(as.numeric(wonder$Population)),
  aar_dl       = suppressWarnings(as.numeric(wonder[["Age Adjusted Rate"]])),
  aar_lo       = suppressWarnings(as.numeric(wonder[["Age Adjusted Rate Lower 95% Confidence Interval"]])),
  aar_hi       = suppressWarnings(as.numeric(wonder[["Age Adjusted Rate Upper 95% Confidence Interval"]])),
  unreliable   = wonder[["Age Adjusted Rate"]] == "Unreliable"
)

# As reported in the paper, when WONDER reports the CI but reports the rate as unreliable, I use the average of the confidence limits as the rate
wonder$aar_dl <- ifelse(wonder$unreliable, (wonder$aar_lo + wonder$aar_hi) / 2, wonder$aar_dl)  #replace unreliable rate
wonder$ln_rate_dl <- log(wonder$aar_dl)                                                         #create the log rate
#print number of unreliable state*year observations
cat("Out of the", nrow(wonder), "observations, the number of unreliables rates replaced by CI midpoint are:",  sum(wonder$unreliable), "\n")

#Check that the panel is balanced
all(table(wonder$state, wonder$Year) == 1) #it is not,let's explore

wonder %>%
  count(state, Year) %>%
  complete(state, Year, fill = list(n = 0)) %>%
  filter(n != 1)      # for some state-year combinations where the number of deaths is zero, CDC wonder doesn't export the row.
  
### Import and cleaning BLS data and merge it to mortality (wonder)
# Data is from BLS LAUS "Employment status of the civilian noninstitutional population, annual averages", available at https://www.bls.gov/lau/tables.htm#stateaa

bls <- read_excel(here("data", "downloaded-data", "staadata.xlsx"), col_names = FALSE, skip = 8,
                  .name_repair = "minimal")
bls <- data.frame(state   = bls[[2]],
                  Year    = suppressWarnings(as.integer(bls[[3]])),
                  unemp_dl = suppressWarnings(as.numeric(bls[[10]])))
bls <- bls[bls$state %in% state.name & bls$Year %in% 1999:2017, ]   #only keeps 50 states (state.name is from the dataset package), and years 199-2017


#Check that the panel is balanced
all(table(bls$state, bls$Year) == 1) #balanced


### Import replication package
rep_pkg <- read.csv(here("data", "replication-package", "pnas.1903434116.sd01.csv"))

## I rename the variables in the replication package that I will later merge to my data
rep_pkg <- rep_pkg %>%
  transmute(state, Year,
            deaths_rep  = Deaths,
            pop_rep     = Population,
            aar_rep     = exp(ln_age_mort_rate),         # rate used in the paper's regressions
            ln_rate_rep = ln_age_mort_rate,
            unemp_rep   = round(unemployment, 1),
            Medical_Cannabis_Law, comprehensive_medical_cannabis, low_thc, recreational_cannabis_law,
            rxdmp_original, rxid_original, pmlaw_original)

#Check that the panel is balanced


# Merge the downloaded mortality and BLS data to it 
analysis_data <- rep_pkg %>%
  left_join(wonder, by = c("state", "Year")) %>%
  left_join(bls, by = c("state", "Year"))
cat("Analysis data rows:", nrow(analysis_data), " matched to WONDER:", sum(!is.na(analysis_data$pop_dl)),
    " matched to BLS:", sum(!is.na(analysis_data$unemp_dl)), "\n")

## Compare mortality and unemployment rates by states and year and record differences
# Both mortality rates and unemployment rates are adjusted over time, so differences likely depend on when the webpage is accessed
analysis_data <- analysis_data %>%
  mutate(diff_deaths = deaths_dl - deaths_rep,
         diff_pop    = pop_dl - pop_rep,
         diff_rate   = round(aar_dl - aar_rep, 2),
         diff_unemp  = round(unemp_dl - unemp_rep, 1))

discrepancies <- analysis_data %>%
  group_by(Year) %>%
  summarise(
    deaths_compared   = sum(!is.na(diff_deaths)),
    deaths_exact      = sum(diff_deaths == 0, na.rm = TRUE),
    deaths_mean_diff  = round(mean(diff_deaths, na.rm = TRUE), 2),
    pop_exact         = sum(diff_pop == 0, na.rm = TRUE),
    rate_compared     = sum(!is.na(diff_rate)),
    rate_within_0.1   = sum(abs(diff_rate) <= 0.1, na.rm = TRUE),
    rate_max_abs_diff = max(abs(diff_rate), na.rm = TRUE),
    unemp_compared    = sum(!is.na(diff_unemp)),
    unemp_exact       = sum(diff_unemp == 0, na.rm = TRUE),
    unemp_mean_abs    = round(mean(abs(diff_unemp), na.rm = TRUE), 2),
    unemp_max_abs     = max(abs(diff_unemp), na.rm = TRUE),
    .groups = "drop")
print(as.data.frame(discrepancies))

# Missing in one source but not the other
cat("Rate missing in rep_pkg but present in download:", sum(is.na(analysis_data$aar_rep) & !is.na(analysis_data$aar_dl)), "\n")
cat("Rate present in rep_pkg but missing in download:", sum(!is.na(analysis_data$aar_rep) & is.na(analysis_data$aar_dl)), "\n")
cat("Unemployment missing in rep_pkg but present in BLS:", sum(is.na(analysis_data$unemp_rep) & !is.na(analysis_data$unemp_dl)), "\n")
missing_unemp <- analysis_data %>%
  filter(is.na(unemp_rep), !is.na(unemp_dl)) %>%
  select(state, Year, unemp_rep, unemp_dl) %>%
  arrange(state, Year)
print(missing_unemp)

missing_unemp %>% count(state)

# State-years where the replication package has no unemployment but BLS does
missing_unemp <- analysis_data[is.na(analysis_data$unemp_rep) & !is.na(analysis_data$unemp_dl),
                               c("state", "Year", "unemp_rep", "unemp_dl")]
print(missing_unemp)    #Missing 2011-2017 for NH and TN



#Export summary tables with discrepancies
write.csv(discrepancies, file.path(tables_dir, "discrepancies_by_year.csv"), row.names = FALSE)
write.csv(analysis_data %>% filter(diff_deaths != 0 | abs(diff_rate) > 0.1 | diff_unemp != 0) %>%
            select(state, Year, deaths_rep, deaths_dl, aar_rep, aar_dl, unemp_rep, unemp_dl),
          file.path(tables_dir, "discrepancies_state_year.csv"), row.names = FALSE)
writeLines(kable(discrepancies, format = "latex", booktabs = TRUE,
                 caption = "Downloaded data vs. replication package, by year"),
           file.path(tables_dir, "discrepancies_by_year.tex"))

# Scatter of the downloaded values against package values
compare_long <- rbind(
  data.frame(variable = "Age-adjusted opioid overdose death rate (per 100,000)",
             package = analysis_data$aar_rep, downloaded = analysis_data$aar_dl, Year = analysis_data$Year),
  data.frame(variable = "Unemployment rate (%)",
             package = analysis_data$unemp_rep, downloaded = analysis_data$unemp_dl, Year = analysis_data$Year))

p <- ggplot(compare_long, aes(x = package, y = downloaded, colour = Year)) +
  geom_abline(intercept = 0, slope = 1, colour = "grey50") +
  geom_point(size = 1, alpha = 0.7, na.rm = TRUE) +
  facet_wrap(~ variable, scales = "free") +
  labs(title = "Downloaded data vs. Shover et al. (2019) replication package",
       x = "Replication package", y = "Downloaded (CDC WONDER / BLS)") +
  theme_minimal()
ggsave(filename = file.path(figures_dir, "discrepancies.png"), plot = p, width = 10, height = 4.5)

print(p)


# Save the analysis dataset
write.csv(analysis_data, file.path(clean_dir, "analysis_data.csv"), row.names = FALSE)
