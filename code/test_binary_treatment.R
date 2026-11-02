### test_binary_treatment.R  (test script, not part of the main replication)
### Does the gap between Bachhuber et al. (2014), -24.8% (-37.5, -9.5), and Shover et al.'s replication,
### -21.1% (-35.7, -3.0), come from how treatment is coded in the adoption year?
### Shover et al. code the law as a fraction of the year in force. Here I re-estimate the 1999-2010 main model
### with several binary codings of the same law dates (replication-package outcome and covariates).

source(here::here("code", "00_setup.R"))

analysis_data <- read.csv(file.path(clean_dir, "analysis_data.csv"))
d <- analysis_data %>% filter(Year <= 2010)

# Adoption-year share in force (0 < share < 1 only in the adoption year)
d$share <- d$Medical_Cannabis_Law

# Binary codings
d$mcl_any      <- as.integer(d$share > 0)      # treated from the adoption year on, however late in the year
d$mcl_half     <- as.integer(d$share >= 0.5)   # treated in the adoption year only if in force for at least half of it
d$mcl_full     <- as.integer(d$share == 1)     # treated only from the first full year (adoption year = 0)

# Bachhuber et al. coding of the two laws that started at the end of 2010: they counted Arizona and
# New Jersey as effective after the study period. The package codes Arizona as 0.047 in 2010
# (New Jersey is already 0 until 2012 in the package).
d$share_bach   <- ifelse(d$state == "Arizona" & d$Year == 2010, 0, d$share)
d$mcl_any_bach <- as.integer(d$share_bach > 0)

codings <- c(
  "Fractional (paper)"                          = "share",
  "Fractional, Arizona 2010 = 0"                = "share_bach",
  "Binary: any part of the year"                = "mcl_any",
  "Binary: any part of the year, Arizona 2010 = 0" = "mcl_any_bach",
  "Binary: at least half of the year"           = "mcl_half",
  "Binary: full years only"                     = "mcl_full")

se_paper <- vcov_cluster("state", ssc = ssc(adj = FALSE, cluster.adj = FALSE))

results <- data.frame()
for (label in names(codings)) {
  v <- codings[[label]]
  f <- as.formula(paste("ln_rate_rep ~", v, "+ rxdmp_original + rxid_original + pmlaw_original + unemp_rep | state + Year"))
  m <- feols(f, data = d, vcov = se_paper, notes = FALSE)
  b <- coef(m)[v]
  s <- se(m)[v]
  results <- rbind(results, data.frame(
    coding = label,
    estimate = sprintf("%.1f (%.1f, %.1f)", 100 * (exp(b) - 1), 100 * (exp(b - 1.96 * s) - 1), 100 * (exp(b + 1.96 * s) - 1)),
    treated_state_years = sum(d[[v]] > 0),
    N = nobs(m), row.names = NULL))
}
results <- rbind(data.frame(coding = "Bachhuber et al. (2014), reported", estimate = "-24.8 (-37.5, -9.5)",
                            treated_state_years = NA, N = NA),
                 results)
print(results)
write.csv(results, file.path(tables_dir, "test_binary_treatment.csv"), row.names = FALSE)
