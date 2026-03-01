# =============================================================================
# 09_results.R — Assemble results list and save to RDS for the Rmd
# =============================================================================

results <- list(
  # Data dimensions
  n_barris = nrow(sf_analysis),
  n_pois_total = nrow(sf_pois),
  poi_summary = poi_summary,

  # Descriptive stats
  access_min = min(sf_analysis$access_score),
  access_max = max(sf_analysis$access_score),
  access_mean = mean(sf_analysis$access_score),
  income_min = min(sf_analysis$income_eur),
  income_max = max(sf_analysis$income_eur),
  rfd_min = min(sf_analysis$rfd_index),
  rfd_max = max(sf_analysis$rfd_index),
  popdens_min = min(sf_analysis$pop_density),
  popdens_max = max(sf_analysis$pop_density),
  avg_neighbors = mean(card(nb_queen)),

  # Moran's I
  moran_I = moran_access$estimate[1],
  moran_p = moran_access$p.value,
  moran_resid_I = moran_resid$statistic,
  moran_resid_p = moran_resid$p.value,

  # OLS
  ols_summary = summary(ols_model),
  ols_coefs = coef(summary(ols_model)),
  ols_r2 = summary(ols_model)$r.squared,
  ols_adjr2 = summary(ols_model)$adj.r.squared,
  ols_aic = AIC(ols_model),
  ols_loglik = as.numeric(logLik(ols_model)),

  # SAR
  sar_rho = sar_model$rho,
  sar_rho_se = sar_model$rho.se,
  sar_aic = AIC(sar_model),
  sar_loglik = as.numeric(logLik(sar_model)),

  # SEM
  sem_aic = AIC(sem_model),
  sem_loglik = as.numeric(logLik(sem_model)),

  # SDM
  sdm_summary = summary(sdm_model),
  sdm_coefs = summary(sdm_model)$Coef,
  sdm_rho = sdm_model$rho,
  sdm_rho_se = sdm_model$rho.se,
  sdm_rho_p = summary(sdm_model)$Wald1$p.value,
  sdm_aic = AIC(sdm_model),
  sdm_loglik = as.numeric(logLik(sdm_model)),
  sdm_impacts_summary = sdm_impacts_smry,
  sdm_direct = sdm_impacts_smry$res$direct,
  sdm_indirect = sdm_impacts_smry$res$indirect,
  sdm_total = sdm_impacts_smry$res$total,
  sdm_pzmat = sdm_impacts_smry$pzmat,

  # SDEM
  sdem_lambda = sdem_model$lambda,
  sdem_lambda_p = summary(sdem_model)$Wald1$p.value,
  sdem_aic = AIC(sdem_model),
  sdem_loglik = as.numeric(logLik(sdem_model)),

  # LR tests
  lr_sdm_sar = lr_sdm_sar,
  lr_sdm_sar_p = lr_sdm_sar_p,
  lr_sdem_sem = lr_sdem_sem,
  lr_sdem_sem_p = lr_sdem_sem_p,

  # Robustness: per-capita
  percap_ols_income_coef = coef(summary(ols_percap))["log_income", 1],
  percap_ols_income_p = coef(summary(ols_percap))["log_income", 4],
  percap_ols_r2 = summary(ols_percap)$r.squared,

  # Robustness: non-linear
  nonlin_quad_coef = coef(summary(ols_nonlin))["log_income_sq", 1],
  nonlin_quad_p = coef(summary(ols_nonlin))["log_income_sq", 4],

  # Robustness: category-specific
  cat_results = cat_results,

  # Robustness: alternative threshold (10-min walk or 800m Euclidean)
  ols_alt_income_coef = coef(summary(ols_alt))["log_income", 1],
  ols_alt_income_p = coef(summary(ols_alt))["log_income", 4],
  sdm_alt_rho = sdm_alt$rho,
  sdm_alt_rho_p = summary(sdm_alt)$Wald1$p.value,
  sdm_alt_coefs = summary(sdm_alt)$Coef,
  use_network = use_network,
  eucl_network_cor = if (use_network && exists("eucl_network_cor")) eucl_network_cor else NA,

  # Extension: gravity-weighted accessibility
  gravity_ols_income_coef = coef(summary(ols_gravity))["log_income", 1],
  gravity_ols_income_p = coef(summary(ols_gravity))["log_income", 4],
  gravity_ols_r2 = summary(ols_gravity)$r.squared,
  gravity_sdm_rho = sdm_gravity$rho,
  gravity_sdm_rho_p = summary(sdm_gravity)$Wald1$p.value,
  gravity_sdm_impacts = sdm_gravity_impacts_smry,
  gravity_sdm_direct = sdm_gravity_impacts_smry$res$direct,
  gravity_sdm_indirect = sdm_gravity_impacts_smry$res$indirect,
  gravity_sdm_total = sdm_gravity_impacts_smry$res$total,
  gravity_sdm_pzmat = sdm_gravity_impacts_smry$pzmat,
  beta_decay = beta_decay,

  # Extension: market access
  ma_ols_income_coef = coef(summary(ols_ma))["log_income", 1],
  ma_ols_income_p = coef(summary(ols_ma))["log_income", 4],
  ma_ols_r2 = summary(ols_ma)$r.squared,
  ma_ols_ma_coef = coef(summary(ols_ma))["log_market_access", 1],
  ma_ols_ma_p = coef(summary(ols_ma))["log_market_access", 4],
  ma_sdm_rho = sdm_ma$rho,
  ma_sdm_rho_p = summary(sdm_ma)$Wald1$p.value,
  ma_sdm_impacts = summary(sdm_ma_impacts, zstats = TRUE, short = TRUE),

  # Extension: Gini coefficients
  gini_total = gini_total,
  gini_percap = gini_percap,
  gini_gravity = gini_gravity,
  gini_by_cat = gini_by_cat,

  # Additional stats for inline R code in Rmd
  area_min_km2 = min(sf_analysis$area_km2),
  area_max_km2 = max(sf_analysis$area_km2),
  pop_min = min(sf_analysis$population),
  pop_max = max(sf_analysis$population),
  lorenz_at_40pct = lorenz_at_40pct,
  n_sdm_params = length(coef(sdm_model)) + 1,  # +1 for rho

  # Temporal analysis: income evolution 2015–2022
  renda_years = sort(unique(df_panel$year)),
  gini_income_by_year = setNames(gini_by_year$gini, gini_by_year$year),
  gini_income_2015 = gini_income_2015,
  gini_income_2022 = gini_income_2022,
  gini_income_change = gini_income_change,
  beta_convergence_coef = beta_convergence_coef,
  beta_convergence_p = beta_convergence_p,
  beta_convergence_r2 = beta_convergence_r2,
  income_growth_mean = income_growth_mean,
  income_growth_min = income_growth_min,
  income_growth_max = income_growth_max
)

saveRDS(results, file.path(output_dir, "results.rds"))
message("Results saved. All figures in: ", output_dir)
