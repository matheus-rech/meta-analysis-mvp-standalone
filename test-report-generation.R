#!/usr/bin/env Rscript

# Test report generation
setwd("/Users/matheusrech/Desktop/meta-analysis-mvp-standalone")

# Create a complete test session
session_id <- "test-report-session"
session_path <- file.path("sessions", session_id)

# Set up session
dir.create(session_path, recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(session_path, "data"), recursive = TRUE)
dir.create(file.path(session_path, "results"), recursive = TRUE)
dir.create(file.path(session_path, "processing"), recursive = TRUE)

# Create session config
session_config <- list(
  id = session_id,
  name = "Test Report Generation",
  studyType = "clinical_trial",
  effectMeasure = "OR",
  analysisModel = "random",
  createdAt = as.character(Sys.time())
)
jsonlite::write_json(session_config, file.path(session_path, "session.json"), pretty = TRUE)

# Copy data
file.copy("test-data/sample_data.csv", 
          file.path(session_path, "data", "uploaded_data.csv"), 
          overwrite = TRUE)

# Run analysis and save results
source("scripts/meta_adapter.R")
data <- read.csv(file.path(session_path, "data", "uploaded_data.csv"))
meta_result <- perform_meta_analysis_core(data, "random", "OR")

# Save meta result
saveRDS(meta_result, file.path(session_path, "results", "analysis_results.rds"))

# Create JSON results
results_json <- list(
  status = "success",
  overall_effect = exp(meta_result$TE.random),
  confidence_interval = list(
    lower = exp(meta_result$lower.random),
    upper = exp(meta_result$upper.random)
  ),
  p_value = meta_result$pval.random,
  heterogeneity = list(
    i_squared = paste0(round(meta_result$I2 * 100, 1), "%"),
    tau_squared = meta_result$tau2,
    q_test = list(
      statistic = meta_result$Q,
      p_value = meta_result$pval.Q
    ),
    interpretation = "Low heterogeneity"
  ),
  study_count = meta_result$k
)
jsonlite::write_json(results_json, 
                     file.path(session_path, "results", "meta_analysis_results.json"), 
                     pretty = TRUE)

# Generate plots
forest_file <- generate_forest_plot_core(
  meta_result, 
  file.path(session_path, "results", "forest_plot.png"),
  "Forest Plot"
)

funnel_file <- generate_funnel_plot_core(
  meta_result,
  file.path(session_path, "results", "funnel_plot.png"),
  "Funnel Plot"
)

# Create bias results
bias_results <- assess_publication_bias_core(meta_result)
jsonlite::write_json(bias_results,
                     file.path(session_path, "results", "publication_bias_results.json"),
                     pretty = TRUE)

cat("Setup complete. Now testing report generation...\n\n")

# Test report generation
library(rmarkdown)
library(knitr)

template_path <- "templates/report_template.Rmd"
output_path <- file.path(session_path, "results", "test_report.html")

tryCatch({
  rmarkdown::render(
    input = template_path,
    output_file = output_path,
    params = list(
      project_name = "Test Report Generation",
      session_path = session_path,
      effect_measure = "OR",
      analysis_model = "random"
    ),
    quiet = TRUE
  )
  cat("✓ Report generated successfully!\n")
  cat("  Output:", output_path, "\n")
}, error = function(e) {
  cat("❌ Error generating report:", e$message, "\n")
})