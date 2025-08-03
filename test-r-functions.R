#!/usr/bin/env Rscript

# Test R functions directly without MCP server
# This tests the core functionality

cat("Testing Meta-Analysis R Functions\n")
cat("=================================\n\n")

# Set up paths
setwd("/Users/matheusrech/Desktop/meta-analysis-mvp-standalone")
session_id <- "test-session-direct"
session_path <- file.path("sessions", session_id)

# Create session directory
dir.create(session_path, recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(session_path, "data"), recursive = TRUE)
dir.create(file.path(session_path, "results"), recursive = TRUE)
dir.create(file.path(session_path, "processing"), recursive = TRUE)

# Create session.json
session_config <- list(
  id = session_id,
  name = "Direct R Test Session",
  studyType = "clinical_trial",
  effectMeasure = "OR",
  analysisModel = "random",
  createdAt = Sys.time()
)
jsonlite::write_json(session_config, file.path(session_path, "session.json"), pretty = TRUE)

cat("1. Testing Data Upload\n")
cat("---------------------\n")

# Copy sample data
file.copy("test-data/sample_data.csv", 
          file.path(session_path, "data", "uploaded_data.csv"), 
          overwrite = TRUE)

# Also save as RDS
data <- read.csv("test-data/sample_data.csv")
saveRDS(data, file.path(session_path, "data", "uploaded_data.rds"))

cat("✓ Data uploaded:", nrow(data), "studies\n")
print(head(data, 3))

cat("\n2. Testing Meta-Analysis\n")
cat("------------------------\n")

# Source the analysis script
source("scripts/perform_analysis.R")

# Run analysis
args_analysis <- list(
  session_path = session_path,
  heterogeneity_test = TRUE,
  publication_bias = TRUE,
  sensitivity_analysis = FALSE
)

result <- tryCatch({
  perform_meta_analysis(args_analysis)
}, error = function(e) {
  cat("Error:", e$message, "\n")
  NULL
})

if (!is.null(result) && result$status == "success") {
  cat("✓ Analysis completed successfully\n")
  cat("  - Pooled effect:", result$overall_effect, "\n")
  cat("  - 95% CI: [", result$confidence_interval$lower, ",", 
      result$confidence_interval$upper, "]\n")
  cat("  - I²:", result$heterogeneity$i_squared, "\n")
  cat("  - P-value:", result$p_value, "\n")
}

cat("\n3. Testing Forest Plot\n")
cat("----------------------\n")

# Source forest plot script
source("scripts/generate_forest_plot.R")

# Generate forest plot
args_forest <- list(
  session_path = session_path,
  plot_style = "classic",
  confidence_level = 0.95
)

forest_result <- tryCatch({
  generate_forest_plot(args_forest)
}, error = function(e) {
  cat("Error:", e$message, "\n")
  NULL
})

if (!is.null(forest_result) && forest_result$status == "success") {
  cat("✓ Forest plot generated:", forest_result$forest_plot_path, "\n")
}

cat("\n4. Testing Publication Bias\n")
cat("---------------------------\n")

# Source bias script
source("scripts/assess_publication_bias.R")

# Assess bias
args_bias <- list(
  session_path = session_path,
  methods = c("funnel_plot", "egger_test", "begg_test")
)

bias_result <- tryCatch({
  assess_publication_bias(args_bias)
}, error = function(e) {
  cat("Error:", e$message, "\n")
  NULL
})

if (!is.null(bias_result) && bias_result$status == "success") {
  cat("✓ Bias assessment completed\n")
  if (!is.null(bias_result$egger_test)) {
    cat("  - Egger test p-value:", bias_result$egger_test$p_value, "\n")
  }
  if (!is.null(bias_result$funnel_plot_path)) {
    cat("  - Funnel plot:", bias_result$funnel_plot_path, "\n")
  }
}

cat("\n5. Testing Report Generation\n")
cat("----------------------------\n")

# Source report script
source("scripts/generate_report.R")

# Generate report
args_report <- list(
  session_path = session_path,
  format = "html",
  include_code = FALSE
)

report_result <- tryCatch({
  generate_report(args_report)
}, error = function(e) {
  cat("Error:", e$message, "\n")
  NULL
})

if (!is.null(report_result) && report_result$status == "success") {
  cat("✓ Report generated:", report_result$file_path, "\n")
}

cat("\n6. Testing Session Status\n")
cat("-------------------------\n")

# Source status script
source("scripts/get_session_status.R")

# Get status
args_status <- list(
  session_path = session_path
)

status_result <- tryCatch({
  get_session_status(args_status)
}, error = function(e) {
  cat("Error:", e$message, "\n")
  NULL
})

if (!is.null(status_result) && status_result$status == "success") {
  cat("✓ Session status retrieved\n")
  cat("  - Workflow stage:", status_result$workflow_stage, "\n")
  cat("  - Completed steps:", paste(status_result$completed_steps, collapse = ", "), "\n")
  if (!is.null(status_result$files$results)) {
    cat("  - Generated files:\n")
    for (file in status_result$files$results) {
      cat("    •", file, "\n")
    }
  }
}

cat("\n=================================\n")
cat("Testing completed!\n")
cat("Check the", session_path, "directory for outputs.\n")