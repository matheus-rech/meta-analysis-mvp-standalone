#!/usr/bin/env Rscript

# Test script for meta package integration
# This demonstrates how the new implementation works

cat("Meta Package Integration Test\n")
cat("============================\n\n")

# Test data - creating a simple meta-analysis dataset
test_data <- data.frame(
  study_id = c("Study 1", "Study 2", "Study 3", "Study 4", "Study 5"),
  events_treatment = c(15, 12, 29, 18, 14),
  n_treatment = c(100, 95, 150, 110, 105),
  events_control = c(25, 22, 40, 28, 20),
  n_control = c(100, 98, 148, 112, 103),
  stringsAsFactors = FALSE
)

# Alternative format with effect sizes
test_data_generic <- data.frame(
  study_id = c("Study A", "Study B", "Study C", "Study D"),
  effect_size = c(0.65, 0.72, 0.58, 0.81),
  se = c(0.15, 0.18, 0.12, 0.20),
  stringsAsFactors = FALSE
)

# Save test data
cat("1. Creating test data files...\n")
write.csv(test_data, "test_binary_data.csv", row.names = FALSE)
write.csv(test_data_generic, "test_generic_data.csv", row.names = FALSE)
cat("   - test_binary_data.csv created\n")
cat("   - test_generic_data.csv created\n\n")

# Test CLI script
cat("2. Testing CLI script with binary data...\n")
cat("   Running: Rscript scripts/meta_analysis_cli.R analyze test_binary_data.csv test_output/\n\n")

# Create test command
test_cmd <- "Rscript scripts/meta_analysis_cli.R analyze test_binary_data.csv test_output/ random OR"
system(test_cmd)

cat("\n3. Generating forest plot...\n")
forest_cmd <- "Rscript scripts/meta_analysis_cli.R forest test_binary_data.csv test_output/ 'Test Forest Plot'"
system(forest_cmd)

cat("\n4. Generating funnel plot...\n")
funnel_cmd <- "Rscript scripts/meta_analysis_cli.R funnel test_binary_data.csv test_output/"
system(funnel_cmd)

cat("\n5. Assessing publication bias...\n")
bias_cmd <- "Rscript scripts/meta_analysis_cli.R bias test_binary_data.csv test_output/"
system(bias_cmd)

cat("\n\nTest completed! Check the 'test_output' directory for results:\n")
cat("  - meta_analysis_results.json\n")
cat("  - meta_analysis_object.rds\n")
cat("  - forest_plot.png\n")
cat("  - funnel_plot.png\n")
cat("  - publication_bias_results.json\n")

# Test with MCP server format
cat("\n\n6. Testing MCP integration (requires server running)...\n")
cat("   To test MCP integration:\n")
cat("   1. Build the server: npm run build\n")
cat("   2. Start the server: npm start\n")
cat("   3. Use MCP Inspector: npm run inspector\n")
cat("   4. Upload test_binary_data.csv through the upload_study_data tool\n")