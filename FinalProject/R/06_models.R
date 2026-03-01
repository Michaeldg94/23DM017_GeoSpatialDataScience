# =============================================================================
# 05_models.R — OLS, SAR, SEM, SDM, SDEM + model comparison & impacts
# =============================================================================

# OLS baseline ----

reg_formula <- log_access ~ log_income + log_pop_density + log_dist_center

ols_model <- lm(reg_formula, data = sf_analysis)
summary(ols_model)

moran_resid <- lm.morantest(ols_model, w_queen, zero.policy = TRUE)
print(moran_resid)

lm_tests <- lm.RStests(
  ols_model, w_queen,
  test = c("RSlag", "RSerr", "adjRSlag", "adjRSerr"),
  zero.policy = TRUE
)
summary(lm_tests)

# SAR ----

sar_model <- lagsarlm(
  reg_formula, data = sf_analysis, listw = w_queen, zero.policy = TRUE
)
summary(sar_model)

# SEM ----

sem_model <- errorsarlm(
  reg_formula, data = sf_analysis, listw = w_queen, zero.policy = TRUE
)
summary(sem_model)

# SDM ----

sdm_model <- lagsarlm(
  reg_formula, data = sf_analysis, listw = w_queen,
  Durbin = TRUE, zero.policy = TRUE
)
summary(sdm_model)

# SDEM ----

sdem_model <- errorsarlm(
  reg_formula, data = sf_analysis, listw = w_queen,
  Durbin = TRUE, zero.policy = TRUE
)
summary(sdem_model)

# AIC / Log-likelihood comparison ----

aic_table <- data.frame(
  Model = c("OLS", "SAR", "SEM", "SDM", "SDEM"),
  AIC = c(AIC(ols_model), AIC(sar_model), AIC(sem_model),
          AIC(sdm_model), AIC(sdem_model)),
  logLik = c(logLik(ols_model), logLik(sar_model), logLik(sem_model),
             logLik(sdm_model), logLik(sdem_model))
) |>
  arrange(AIC)

print(aic_table)

# Likelihood ratio tests ----

lr_sdm_sar <- as.numeric(2 * (logLik(sdm_model) - logLik(sar_model)))
lr_sdm_sar_df <- length(coef(sdm_model)) - length(coef(sar_model))
lr_sdm_sar_p <- pchisq(lr_sdm_sar, df = lr_sdm_sar_df, lower.tail = FALSE)

lr_sdem_sem <- as.numeric(2 * (logLik(sdem_model) - logLik(sem_model)))
lr_sdem_sem_df <- length(coef(sdem_model)) - length(coef(sem_model))
lr_sdem_sem_p <- pchisq(lr_sdem_sem, df = lr_sdem_sem_df, lower.tail = FALSE)

message("LR test SDM vs SAR: ", round(lr_sdm_sar, 3),
        " (p = ", round(lr_sdm_sar_p, 4), ")")
message("LR test SDEM vs SEM: ", round(lr_sdem_sem, 3),
        " (p = ", round(lr_sdem_sem_p, 4), ")")

# SDM impact decomposition ----

sdm_impacts <- impacts(sdm_model, listw = w_queen, R = 500)
sdm_impacts_smry <- summary(sdm_impacts, zstats = TRUE, short = TRUE)
print(sdm_impacts_smry)

sar_impacts <- impacts(sar_model, listw = w_queen, R = 500)
print(summary(sar_impacts, zstats = TRUE, short = TRUE))
