#!/usr/bin/env Rscript

# Meta-Analysis MCP Tools - Real Implementation

suppressPackageStartupMessages({
  library(jsonlite)
  library(metafor)
  library(ggplot2)
})

# Get command line arguments
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) {
  stop("Usage: mcp_tools.R <tool_name> <json_args> [session_path]")
}

tool_name <- args[1]
json_args <- fromJSON(args[2])
session_path <- if (length(args) >= 3) args[3] else getwd()

# Helper function to write JSON response
respond <- function(data) {
  cat(toJSON(data, auto_unbox = TRUE, pretty = TRUE))
}

# Helper function to write error response
error_response <- function(message) {
  respond(list(
    status = "error",
    message = message
  ))
}

# Main tool handler
tryCatch({
  switch(tool_name,
    "upload_study_data" = {
      # Parse the CSV data
      data_content <- json_args$data_content
      data_format <- json_args$data_format
      
      if (data_format != "csv") {
        error_response("Only CSV format is supported in MVP")
        quit(status = 1)
      }
      
      # Read CSV from string
      df <- read.csv(text = data_content, stringsAsFactors = FALSE)
      
      # Basic validation
      required_cols <- c("study", "effect_size", "variance")
      missing_cols <- setdiff(required_cols, names(df))
      
      if (length(missing_cols) > 0) {
        error_response(paste("Missing required columns:", paste(missing_cols, collapse = ", ")))
        quit(status = 1)
      }
      
      # Calculate standard errors if not provided
      if (!"se" %in% names(df)) {
        df$se <- sqrt(df$variance)
      }
      
      # Save data to session
      data_file <- file.path(session_path, "data", "uploaded_data.csv")
      dir.create(dirname(data_file), showWarnings = FALSE, recursive = TRUE)
      write.csv(df, data_file, row.names = FALSE)
      
      # Save as RDS for faster loading
      saveRDS(df, file.path(session_path, "data", "uploaded_data.rds"))
      
      respond(list(
        status = "success",
        message = paste("Uploaded", nrow(df), "studies"),
        rows = nrow(df),
        columns = ncol(df),
        preview = head(df, 3)
      ))
    },
    
    "perform_meta_analysis" = {
      # Load data
      data_file <- file.path(session_path, "data", "uploaded_data.rds")
      if (!file.exists(data_file)) {
        error_response("No data uploaded. Please upload data first.")
        quit(status = 1)
      }
      
      df <- readRDS(data_file)
      
      # Perform meta-analysis using metafor
      model_type <- json_args$analysis_model
      if (is.null(model_type) || model_type == "auto") {
        model_type <- "random"
      }
      
      # Run meta-analysis
      if (model_type == "random") {
        ma_result <- rma(yi = effect_size, vi = variance, data = df, method = "REML")
      } else {
        ma_result <- rma(yi = effect_size, vi = variance, data = df, method = "FE")
      }
      
      # Extract results
      results <- list(
        overall_effect = as.numeric(ma_result$beta),
        se = as.numeric(ma_result$se),
        ci_lower = as.numeric(ma_result$ci.lb),
        ci_upper = as.numeric(ma_result$ci.ub),
        z_value = as.numeric(ma_result$zval),
        p_value = as.numeric(ma_result$pval),
        Q = as.numeric(ma_result$QE),
        Q_pvalue = as.numeric(ma_result$QEp),
        df = ma_result$k - 1,
        I_squared = as.numeric(ma_result$I2),
        tau_squared = as.numeric(ma_result$tau2),
        n_studies = ma_result$k,
        model = model_type
      )
      
      # Save results
      results_file <- file.path(session_path, "results", "analysis_results.rds")
      dir.create(dirname(results_file), showWarnings = FALSE, recursive = TRUE)
      saveRDS(list(results = results, model = ma_result), results_file)
      
      respond(list(
        status = "success",
        summary = results
      ))
    },
    
    "generate_forest_plot" = {
      # Check if we have results
      results_file <- file.path(session_path, "results", "analysis_results.rds")
      data_file <- file.path(session_path, "data", "uploaded_data.rds")
      
      if (!file.exists(results_file) || !file.exists(data_file)) {
        error_response("No analysis results found. Please run analysis first.")
        quit(status = 1)
      }
      
      # Load data and results
      df <- readRDS(data_file)
      analysis <- readRDS(results_file)
      ma_result <- analysis$model
      
      # Get plot settings
      plot_style <- json_args$plot_style
      if (is.null(plot_style)) plot_style <- "classic"
      
      # Create forest plot
      plot_path <- file.path(session_path, "results", "forest_plot.png")
      
      png(plot_path, width = 1200, height = 800, res = 120)
      
      # Create forest plot using metafor
      forest(ma_result, 
             slab = df$study,
             xlim = c(-3, 3),
             xlab = "Effect Size (Log Odds Ratio)",
             mlab = paste0("RE Model (I² = ", round(ma_result$I2, 1), "%)"),
             header = TRUE,
             shade = TRUE,
             col = "darkblue",
             border = "darkblue")
      
      # Add custom title if provided
      custom_labels <- json_args$custom_labels
      if (!is.null(custom_labels) && !is.null(custom_labels$title)) {
        title(main = custom_labels$title)
      }
      
      dev.off()
      
      respond(list(
        status = "success",
        plot_path = plot_path,
        plot_type = "forest_plot",
        format = "png"
      ))
    },
    
    "assess_publication_bias" = {
      # Load results
      results_file <- file.path(session_path, "results", "analysis_results.rds")
      data_file <- file.path(session_path, "data", "uploaded_data.rds")
      
      if (!file.exists(results_file) || !file.exists(data_file)) {
        error_response("No analysis results found. Please run analysis first.")
        quit(status = 1)
      }
      
      df <- readRDS(data_file)
      analysis <- readRDS(results_file)
      ma_result <- analysis$model
      
      methods <- json_args$methods
      if (is.null(methods)) {
        methods <- c("funnel_plot", "egger_test")
      }
      
      response_data <- list(status = "success")
      
      # Generate funnel plot
      if ("funnel_plot" %in% methods) {
        funnel_path <- file.path(session_path, "results", "funnel_plot.png")
        
        png(funnel_path, width = 800, height = 800, res = 120)
        
        # Create funnel plot
        funnel(ma_result,
               main = "Funnel Plot for Publication Bias Assessment",
               xlab = "Effect Size",
               ylab = "Standard Error",
               col = "darkgray",
               bg = "lightblue",
               pch = 19)
        
        # Add trim and fill if requested
        if ("trim_fill" %in% methods && ma_result$k >= 5) {
          tf_result <- trimfill(ma_result)
          funnel(tf_result, add = TRUE, col = "red", bg = "pink", pch = 19)
          legend("topright", 
                 legend = c("Observed", "Imputed"), 
                 pch = 19, 
                 col = c("darkgray", "red"),
                 pt.bg = c("lightblue", "pink"))
        }
        
        dev.off()
        
        response_data$funnel_plot_path <- funnel_path
      }
      
      # Perform Egger's test
      if ("egger_test" %in% methods && ma_result$k >= 10) {
        egger_result <- regtest(ma_result, model = "lm")
        response_data$egger_test <- list(
          z_value = as.numeric(egger_result$zval),
          p_value = as.numeric(egger_result$pval),
          interpretation = ifelse(egger_result$pval < 0.05, 
                                  "Significant asymmetry detected (potential publication bias)",
                                  "No significant asymmetry detected")
        )
      } else if ("egger_test" %in% methods) {
        response_data$egger_test <- list(
          p_value = NA,
          message = "Egger's test requires at least 10 studies"
        )
      }
      
      # Perform Begg's test
      if ("begg_test" %in% methods && ma_result$k >= 5) {
        ranktest_result <- ranktest(ma_result)
        response_data$begg_test <- list(
          tau = as.numeric(ranktest_result$tau),
          p_value = as.numeric(ranktest_result$pval),
          interpretation = ifelse(ranktest_result$pval < 0.05,
                                  "Significant correlation detected (potential publication bias)",
                                  "No significant correlation detected")
        )
      } else if ("begg_test" %in% methods) {
        response_data$begg_test <- list(
          p_value = NA,
          message = "Begg's test requires at least 5 studies"
        )
      }
      
      respond(response_data)
    },
    
    "generate_report" = {
      # Load all results
      results_file <- file.path(session_path, "results", "analysis_results.rds")
      data_file <- file.path(session_path, "data", "uploaded_data.rds")
      
      if (!file.exists(results_file) || !file.exists(data_file)) {
        error_response("No analysis results found. Please run analysis first.")
        quit(status = 1)
      }
      
      df <- readRDS(data_file)
      analysis <- readRDS(results_file)
      results <- analysis$results
      
      # Generate report based on format
      format <- json_args$format
      if (is.null(format)) format <- "pdf"
      
      if (format == "pdf") {
        # For MVP, create a comprehensive text report that can be converted to PDF
        report_path <- file.path(session_path, "results", "meta_analysis_report.txt")
        
        report_lines <- c(
          "=====================================",
          "META-ANALYSIS REPORT",
          "=====================================",
          paste("Generated:", Sys.time()),
          "",
          "STUDY INFORMATION",
          "-----------------",
          paste("Number of studies:", results$n_studies),
          paste("Total sample size:", sum(df$sample_size, na.rm = TRUE)),
          paste("Model type:", toupper(results$model)),
          "",
          "OVERALL EFFECT",
          "--------------",
          paste("Effect size:", round(results$overall_effect, 3)),
          paste("Standard error:", round(results$se, 3)),
          paste("95% CI: [", round(results$ci_lower, 3), ", ", round(results$ci_upper, 3), "]", sep = ""),
          paste("Z-value:", round(results$z_value, 3)),
          paste("P-value:", format.pval(results$p_value, digits = 3)),
          "",
          "HETEROGENEITY",
          "-------------",
          paste("Q statistic:", round(results$Q, 2)),
          paste("Q p-value:", format.pval(results$Q_pvalue, digits = 3)),
          paste("I² statistic:", round(results$I_squared, 1), "%", sep = ""),
          paste("τ² (tau-squared):", round(results$tau_squared, 4)),
          "",
          "INTERPRETATION",
          "--------------"
        )
        
        # Add interpretation
        if (results$p_value < 0.05) {
          report_lines <- c(report_lines,
            "The overall effect is statistically significant.",
            paste("The pooled effect size is", round(results$overall_effect, 3))
          )
        } else {
          report_lines <- c(report_lines,
            "The overall effect is not statistically significant."
          )
        }
        
        if (results$I_squared < 25) {
          report_lines <- c(report_lines, "Low heterogeneity detected.")
        } else if (results$I_squared < 50) {
          report_lines <- c(report_lines, "Moderate heterogeneity detected.")
        } else if (results$I_squared < 75) {
          report_lines <- c(report_lines, "Substantial heterogeneity detected.")
        } else {
          report_lines <- c(report_lines, "Considerable heterogeneity detected.")
        }
        
        # Add study details
        report_lines <- c(report_lines,
          "",
          "INDIVIDUAL STUDY RESULTS",
          "------------------------"
        )
        
        for (i in 1:nrow(df)) {
          report_lines <- c(report_lines,
            paste(df$study[i], ": ES =", round(df$effect_size[i], 3), 
                  ", SE =", round(sqrt(df$variance[i]), 3))
          )
        }
        
        writeLines(report_lines, report_path)
        
        respond(list(
          status = "success",
          report_path = report_path,
          format = "text",
          message = "Text report generated. Can be converted to PDF using external tools."
        ))
        
      } else {
        error_response("Only PDF/text format is supported in MVP")
      }
    },
    
    {
      error_response(paste("Unknown tool:", tool_name))
    }
  )
}, error = function(e) {
  error_response(paste("R script error:", e$message))
})