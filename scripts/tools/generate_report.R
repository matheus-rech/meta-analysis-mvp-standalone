# generate_report.R
# Updated to use R Markdown template for personalized reports

library(jsonlite)
library(rmarkdown)
library(knitr)

generate_report <- function(args) {
  session_path <- args$session_path
  
  # Validate inputs
  if (is.null(args$format) || !args$format %in% c("html", "pdf", "word")) {
    stop("Invalid report format. Must be 'html', 'pdf', or 'word'")
  }
  
  # Create output directory if it doesn't exist
  output_dir <- file.path(session_path, "results")
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  
  # Load session configuration
  session_config_path <- file.path(session_path, "session.json")
  if (!file.exists(session_config_path)) {
    stop("Session configuration not found.")
  }
  session_config <- fromJSON(session_config_path)
  
  # Set report filename
  report_filename <- switch(args$format,
    "html" = "meta_analysis_report.html",
    "pdf" = "meta_analysis_report.pdf",
    "word" = "meta_analysis_report.docx"
  )
  report_path <- file.path(output_dir, report_filename)
  
  # Get template path
  script_dir <- dirname(sys.frame(1)$ofile)
  if (is.null(script_dir)) {
    # Fallback for command line execution
    args_cmd <- commandArgs(trailingOnly = FALSE)
    script_file <- args_cmd[grep("--file=", args_cmd)]
    if (length(script_file) > 0) {
      script_dir <- dirname(gsub("--file=", "", script_file))
    } else {
      script_dir <- getwd()
    }
  }
  
  # Look for template
  template_path <- file.path(dirname(script_dir), "..", "templates", "report_template.Rmd")
  
  # Use journal-specific template if requested
  if (!is.null(args$journal_template)) {
    journal_template_path <- file.path(dirname(script_dir), "templates", 
                                       paste0(args$journal_template, "_template.Rmd"))
    if (file.exists(journal_template_path)) {
      template_path <- journal_template_path
    } else {
      warning(paste("Journal template", args$journal_template, "not found. Using default template."))
    }
  }
  
  # Check if template exists
  if (!file.exists(template_path)) {
    stop(paste("Report template not found at:", template_path))
  }
  
  # Prepare parameters for R Markdown
  render_params <- list(
    project_name = session_config$name,
    session_path = session_path,
    effect_measure = session_config$effectMeasure,
    analysis_model = session_config$analysisModel
  )
  
  # Set output format
  output_format <- switch(args$format,
    "html" = html_document(
      theme = "flatly",
      toc = TRUE,
      toc_float = TRUE,
      code_folding = "hide",
      fig_width = 10,
      fig_height = 6
    ),
    "pdf" = pdf_document(
      toc = TRUE,
      fig_width = 8,
      fig_height = 6
    ),
    "word" = word_document(
      toc = TRUE,
      fig_width = 8,
      fig_height = 6
    )
  )
  
  tryCatch({
    # Render the report
    rmarkdown::render(
      input = template_path,
      output_file = report_path,
      output_format = output_format,
      params = render_params,
      quiet = TRUE,
      envir = new.env()
    )
    
    # Return success response
    list(
      status = "success",
      message = paste("Report generated successfully in", args$format, "format"),
      file_path = report_path,
      format = args$format,
      project_name = session_config$name,
      timestamp = Sys.time()
    )
    
  }, error = function(e) {
    list(
      status = "error",
      message = paste("Error generating report:", e$message),
      details = list(
        format = args$format,
        template_path = template_path,
        session_path = session_path
      )
    )
  })
}