###02_replicate.R

#Replicate Table 1 and Figure 1 of Shover et al. (2019, PNAS) twice:
#  (a) "package":    outcome and unemployment from the replication package (exact replication)
#  (b) "downloaded": outcome from my CDC WONDER download and unemployment from my BLS download
#Main specification: log(age-adjusted opioid overdose death rate) on the law(s) + 4 covariates, state and year FE.
#Effects are reported as 100 * (exp(b) - 1). Standard errors are clustered by state with no small-sample

source(here::here("code", "00_setup.R"))

#Replicate using the dataset created in cleaning
analysis_data <- read.csv(file.path(clean_dir, "analysis_data.csv"))

# Same variable names for the two versions of the data
# (_rep = replication package, _dl = my downloads; names as created in 01_cleaning.R)
d_package    <- analysis_data %>% mutate(ln_rate = ln_rate_rep, unemployment = unemp_rep)
d_downloaded <- analysis_data %>% mutate(ln_rate = ln_rate_dl, unemployment = unemp_dl)
data_versions <- list(package = d_package, downloaded = d_downloaded)

covariates <- "rxdmp_original + rxid_original + pmlaw_original + unemployment"
f_main     <- as.formula(paste("ln_rate ~ Medical_Cannabis_Law +", covariates, "| state + Year"))
f_expanded <- as.formula(paste("ln_rate ~ recreational_cannabis_law + comprehensive_medical_cannabis + low_thc +",
                               covariates, "| state + Year"))
se_paper <- vcov_cluster("state", ssc = ssc(adj = FALSE, cluster.adj = FALSE))

# Row order and labels of Table 1
var_names <- c("Medical_Cannabis_Law", "rxdmp_original", "rxid_original", "pmlaw_original", "unemployment",
               "recreational_cannabis_law", "comprehensive_medical_cannabis", "low_thc")
var_labels <- c("Medical cannabis law", "Prescription drug monitoring program",
                "Law requiring or allowing pharmacists to request patient identification",
                "Increased state oversight of pain management clinics", "Annual state unemployment rate",
                "Recreational and medical cannabis law", "Medical cannabis only", "Low-THC-only medical cannabis law")

# Table 1 as printed in the paper, typed in for comparison
reported <- data.frame(
  variable = rep(var_names, 3),
  model = rep(c("Replication (1999-2010)", "Extension (1999-2017)", "Expanded model (1999-2017)"), each = 8),
  reported = c("-21.1 (-35.7, -3.0)", "-2.8 (-16.7, 13.3)", "2.8 (-12.6, 20.9)", "-6.9 (-18.4, 6.2)", "4.4 (-0.3, 9.3)", NA, NA, NA,
               "22.7 (2.0, 47.6)", "-2.7 (-15.9, 12.5)", "11.8 (-7.7, 35.5)", "9.0 (-15.6, 40.8)", "1.4 (-2.7, 5.5)", NA, NA, NA,
               NA, "-4.0 (-17.1, 11.1)", "8.8 (-10.2, 31.9)", "13.7 (-11.2, 45.5)", "0.7 (-3.1, 4.6)",
               "-14.7 (-43.6, 29.0)", "28.2 (1.2, 62.4)", "-7.1 (-29.1, 21.7)"))

#Replicate the table and export it in latex, for both versions with my downloaded data and existing ones
results <- data.frame()
for (version in names(data_versions)) {
  dat <- data_versions[[version]]
  models <- list(
    "Replication (1999-2010)"    = feols(f_main, data = dat %>% filter(Year <= 2010), vcov = se_paper),
    "Extension (1999-2017)"      = feols(f_main, data = dat, vcov = se_paper),
    "Expanded model (1999-2017)" = feols(f_expanded, data = dat, vcov = se_paper))
  for (model_name in names(models)) {
    m <- models[[model_name]]
    b <- coef(m)
    s <- se(m)
    results <- rbind(results, data.frame(
      data = version, model = model_name, variable = names(b), N = nobs(m),
      est = 100 * (exp(b) - 1), lo = 100 * (exp(b - 1.96 * s) - 1), hi = 100 * (exp(b + 1.96 * s) - 1),
      row.names = NULL))
  }
}
results$cell <- sprintf("%.1f (%.1f, %.1f)", results$est, results$lo, results$hi)
write.csv(results, file.path(tables_dir, "table1_all_estimates.csv"), row.names = FALSE)

# (1) Table 1 in the paper's layout, exact replication with the package data
model_order <- c("Replication (1999-2010)", "Extension (1999-2017)", "Expanded model (1999-2017)")
table1 <- data.frame(Variable = var_labels)
for (model_name in model_order) {
  x <- results %>% filter(data == "package", model == model_name)
  table1[[model_name]] <- ifelse(var_names %in% x$variable, x$cell[match(var_names, x$variable)], "N/A")
}
print(table1)
writeLines(kable(table1, format = "latex", booktabs = TRUE,
                 caption = "Replication of Shover et al. (2019) Table 1: percent change in the age-adjusted opioid overdose death rate (95\\% CI). State and year fixed effects; SEs clustered by state."),
           file.path(tables_dir, "table1_replication.tex"))

# (2) Reported vs. package data vs. downloaded data, one row per model and variable
comparison <- reported %>%
  left_join(results %>% filter(data == "package") %>% select(model, variable, package = cell), by = c("model", "variable")) %>%
  left_join(results %>% filter(data == "downloaded") %>% select(model, variable, downloaded = cell), by = c("model", "variable")) %>%
  filter(!is.na(reported)) %>%
  mutate(variable = var_labels[match(variable, var_names)]) %>%
  rename(Model = model, Variable = variable, `Reported in paper` = reported,
         `Replication package data` = package, `Downloaded data` = downloaded)
print(comparison)
write.csv(comparison, file.path(tables_dir, "table1_comparison.csv"), row.names = FALSE)
writeLines(kable(comparison, format = "latex", booktabs = TRUE,
                 caption = "Table 1 as reported, replicated with the package data, and replicated with my downloaded data"),
           file.path(tables_dir, "table1_comparison.tex"))

#Replicate the figure and export it
# Figure 1: estimate of the medical cannabis law coefficient when the sample ends in 2002, 2003, ..., 2017
figure1 <- data.frame()
for (version in names(data_versions)) {
  for (end_year in 2002:2017) {
    m <- feols(f_main, data = data_versions[[version]] %>% filter(Year <= end_year), vcov = se_paper)
    b <- coef(m)["Medical_Cannabis_Law"]
    s <- se(m)["Medical_Cannabis_Law"]
    figure1 <- rbind(figure1, data.frame(data = version, end_year = end_year,
                                         est = 100 * (exp(b) - 1), lo = 100 * (exp(b - 1.96 * s) - 1),
                                         hi = 100 * (exp(b + 1.96 * s) - 1), row.names = NULL))
  }
}

write.csv(figure1, file.path(tables_dir, "figure1_estimates.csv"), row.names = FALSE)

p <- ggplot(figure1 %>% filter(data == "package"), aes(x = end_year, y = est)) +
  geom_hline(yintercept = 0, colour = "red") +
  geom_vline(xintercept = 2010, linetype = "dotted", colour = "black") +
  geom_line() +
  geom_line(aes(y = lo), linetype = "dashed") +
  geom_line(aes(y = hi), linetype = "dashed") +
  scale_x_continuous(breaks = 2002:2017) +
  scale_y_continuous(breaks = seq(-50, 60, 10)) +
  labs(title = "Replication of Shover et al. (2019) Figure 1",
       x = "Study Endpoint", y = "Point Estimate and 95% Confidence Interval") +
  theme_minimal()
ggsave(filename = file.path(figures_dir, "figure1_replication.png"), plot = p, width = 8, height = 5)

print(p)

plot <- ggplot(figure1, aes(x = end_year, y = est, colour = data, fill = data)) +
  geom_hline(yintercept = 0, colour = "grey40") +
  geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.15, colour = NA) +
  geom_line() +
  scale_x_continuous(breaks = 2002:2017) +
  labs(title = "Figure 1 with the replication package data vs. my downloaded data",
       x = "Study Endpoint", y = "Percent change in opioid overdose death rate", colour = NULL, fill = NULL) +
  theme_minimal() + theme(legend.position = "bottom")
ggsave(filename = file.path(figures_dir, "figure1_package_vs_downloaded.png"), plot = p, width = 8, height = 5)

print(plot)