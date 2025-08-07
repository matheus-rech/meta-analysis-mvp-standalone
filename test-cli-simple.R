#!/usr/bin/env Rscript

# Simple test of CLI functionality
setwd("/Users/matheusrech/Desktop/meta-analysis-mvp-standalone")

# Load the adapter directly
source("scripts/meta_adapter.R")

# Read sample data
data <- read.csv("test-data/sample_data.csv")
cat("Loaded", nrow(data), "studies\n")

# Perform meta-analysis
cat("\nPerforming meta-analysis...\n")
meta_result <- perform_meta_analysis_core(data, method = "random", measure = "OR")

# Show results
cat("Pooled OR:", round(exp(meta_result$TE.random), 3), "\n")
cat("95% CI: [", round(exp(meta_result$lower.random), 3), ",", 
    round(exp(meta_result$upper.random), 3), "]\n")
cat("I²:", round(meta_result$I2 * 100, 1), "%\n")
cat("P-value:", format.pval(meta_result$pval.random), "\n")

# Generate forest plot
cat("\nGenerating forest plot...\n")
dir.create("test-output", showWarnings = FALSE)
forest_file <- generate_forest_plot_core(
  meta_result, 
  "test-output/forest_plot.png",
  "Test Forest Plot",
  "classic"
)
cat("Forest plot saved to:", forest_file, "\n")

# Generate funnel plot
cat("\nGenerating funnel plot...\n")
funnel_file <- generate_funnel_plot_core(
  meta_result,
  "test-output/funnel_plot.png",
  "Test Funnel Plot"
)
cat("Funnel plot saved to:", funnel_file, "\n")

# Assess publication bias
cat("\nAssessing publication bias...\n")
bias_results <- assess_publication_bias_core(meta_result)
cat("Egger test p-value:", round(bias_results$egger_test$p_value, 3), "\n")
cat("Interpretation:", bias_results$egger_test$interpretation, "\n")

cat("\n✓ All tests completed successfully!\n")