### 03_bachhuber_figures.R
### Replicate Figures 1 and 2 of Bachhuber et al. (2014, JAMA Internal Medicine), 1999-2010,
### using the dataset created in 01_cleaning.R (replication-package outcome, policies and covariates).
###
### Figure 1: mean age-adjusted opioid analgesic overdose death rate in each year, states with a medical
###           cannabis law vs states without one (unweighted mean across states).
### Figure 2: percent difference in the death rate in each year after the law took effect (years 1-6),
###           from a model with one indicator per year since implementation, state and year FE and the
###           same four covariates as the main model:
###   ln(Y_st) = a_s + l_t + sum_k b_k * 1{years since law = k} + covariates + e_st
###
### Coding choices (Bachhuber et al. do not spell out every detail):
###  - A state "has a law" in a year if Medical_Cannabis_Law > 0 in that year.
###  - Years since implementation = year - adoption year, so the adoption year is 0 and year 1 is the
###    first full year after it. This matches their example: California (law in 1996) is coded 3 in 1999.
###  - The adoption year enters with its fraction of the year in force (as in the main model), and
###    years 6 and later are pooled into "6+".
###  - Adoption years before 1999 come from Bachhuber et al.: California 1996, Oregon 1998, Washington 1998.
###  - The replication package dates Arizona's law to December 2010; Bachhuber et al. counted it as
###    effective after 2010, so the package has 14 adopting states by 2010 instead of their 13.

source(here::here("code", "00_setup.R"))

analysis_data <- read.csv(file.path(clean_dir, "analysis_data.csv"))
bach <- analysis_data %>% filter(Year <= 2010)

### Figure 1: mean death rate, states with vs without a medical cannabis law
bach$law_status <- ifelse(bach$Medical_Cannabis_Law > 0, "States with a medical cannabis law",
                          "States without a medical cannabis law")

fig1_means <- bach %>%
  filter(!is.na(aar_rep)) %>%
  group_by(Year, law_status) %>%
  summarise(mean_rate = mean(aar_rep), n_states = n(), .groups = "drop")
print(as.data.frame(fig1_means))
write.csv(fig1_means, file.path(tables_dir, "bachhuber_figure1_means.csv"), row.names = FALSE)

p <- ggplot(fig1_means, aes(x = Year, y = mean_rate, linetype = law_status)) +
  geom_line() +
  scale_x_continuous(breaks = 1999:2010) +
  scale_y_continuous(limits = c(0, 8), breaks = 0:8) +
  labs(title = "Replication of Bachhuber et al. (2014) Figure 1",
       x = "Year", y = "Age-adjusted opioid analgesic overdose mortality, per 100,000",
       linetype = NULL) +
  theme_minimal() + theme(legend.position = "bottom")
ggsave(filename = file.path(figures_dir, "bachhuber_figure1.png"), plot = p, width = 8, height = 5)

### Figure 2: effect by year since implementation
# Adoption year: first year with Medical_Cannabis_Law > 0; earlier years for states with laws before 1999
adoption <- analysis_data %>%
  filter(Medical_Cannabis_Law > 0) %>%
  group_by(state) %>%
  summarise(adoption_year = min(Year), .groups = "drop")
adoption$adoption_year[adoption$state == "California"] <- 1996
adoption$adoption_year[adoption$state == "Oregon"]     <- 1998
adoption$adoption_year[adoption$state == "Washington"] <- 1998

bach <- bach %>%
  left_join(adoption, by = "state") %>%
  mutate(years_since = Year - adoption_year)          # NA for states without a law by then

# One indicator per year since implementation (0 for states without a law)
bach$year0  <- ifelse(!is.na(bach$years_since) & bach$years_since == 0, bach$Medical_Cannabis_Law, 0)  # fraction of adoption year
bach$year1  <- as.integer(!is.na(bach$years_since) & bach$years_since == 1)
bach$year2  <- as.integer(!is.na(bach$years_since) & bach$years_since == 2)
bach$year3  <- as.integer(!is.na(bach$years_since) & bach$years_since == 3)
bach$year4  <- as.integer(!is.na(bach$years_since) & bach$years_since == 4)
bach$year5  <- as.integer(!is.na(bach$years_since) & bach$years_since == 5)
bach$year6p <- as.integer(!is.na(bach$years_since) & bach$years_since >= 6)

se_paper <- vcov_cluster("state", ssc = ssc(adj = FALSE, cluster.adj = FALSE))
m_event <- feols(ln_rate_rep ~ year0 + year1 + year2 + year3 + year4 + year5 + year6p +
                   rxdmp_original + rxid_original + pmlaw_original + unemp_rep | state + Year,
                 data = bach, vcov = se_paper)
summary(m_event)

event_vars <- c("year1", "year2", "year3", "year4", "year5", "year6p")
b <- coef(m_event)[event_vars]
s <- se(m_event)[event_vars]
fig2_estimates <- data.frame(
  years_after = 1:6,
  label       = c("1", "2", "3", "4", "5", "6+"),
  est = 100 * (exp(b) - 1),
  lo  = 100 * (exp(b - 1.96 * s) - 1),
  hi  = 100 * (exp(b + 1.96 * s) - 1),
  row.names = NULL)

# Number of states contributing to each year-since-law indicator
fig2_estimates$states <- NA
for (i in seq_along(event_vars)) {
  fig2_estimates$states[i] <- n_distinct(bach$state[bach[[event_vars[i]]] == 1])
}

# Bachhuber et al. (2014) Figure 2 / text, for comparison
fig2_estimates$reported <- c("-19.9 (-30.6, -7.7)", "-25.2 (-40.6, -5.9)", "-23.6 (-41.1, -1.0)",
                             "-20.2 (-33.6, -4.0)", "-33.7 (-50.9, -10.4)", "-33.3 (-44.7, -19.6)")
fig2_estimates$replicated <- sprintf("%.1f (%.1f, %.1f)", fig2_estimates$est, fig2_estimates$lo, fig2_estimates$hi)
print(fig2_estimates[, c("label", "reported", "replicated", "states")])
write.csv(fig2_estimates, file.path(tables_dir, "bachhuber_figure2_estimates.csv"), row.names = FALSE)
writeLines(kable(fig2_estimates[, c("label", "reported", "replicated", "states")], format = "latex", booktabs = TRUE,
                 col.names = c("Years after law", "Bachhuber et al. (2014)", "Replication", "States"),
                 caption = "Percent difference in opioid analgesic overdose mortality by year since the medical cannabis law took effect, 1999--2010 (95\\% CI)"),
           file.path(tables_dir, "bachhuber_figure2_estimates.tex"))

p <- ggplot(fig2_estimates, aes(x = years_after, y = est)) +
  geom_hline(yintercept = 0, colour = "grey50") +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = 0.15) +
  geom_line() +
  geom_point(size = 2) +
  scale_x_continuous(breaks = 1:6, labels = fig2_estimates$label) +
  scale_y_continuous(limits = c(-60, 5), breaks = seq(-60, 0, 20)) +
  labs(title = "Replication of Bachhuber et al. (2014) Figure 2",
       x = "Years After Law Implementation, No.", y = "Difference in Age-Adjusted Mortality Rate, %") +
  theme_minimal()
ggsave(filename = file.path(figures_dir, "bachhuber_figure2.png"), plot = p, width = 7, height = 5)
