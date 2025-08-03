# Meta-Analysis Data Format Guide

## Overview

This guide explains the data formats supported by the Meta-Analysis MVP, including required columns, data types, and formatting requirements. Proper data preparation is essential for successful meta-analyses.

## Supported Data Formats

The Meta-Analysis MVP currently supports:
- **CSV format** (primary supported format)
- Future support planned for Excel and RevMan formats

## Required Data Structure

### Basic Structure

At minimum, all datasets must include:

| Column | Description | Data Type | Required |
|--------|-------------|-----------|----------|
| `study` | Study identifier | String | Yes |
| `effect_size` | The calculated effect size | Numeric | Yes |
| `variance` | Variance of the effect size | Numeric | Yes |

If `variance` is not available but standard error is, include:
| Column | Description | Data Type | Required |
|--------|-------------|-----------|----------|
| `se` | Standard error of the effect size | Numeric | Yes (if no variance) |

The system will calculate `variance = se^2` if only `se` is provided.

### Optional Columns

For richer analyses, include:
| Column | Description | Data Type | Required |
|--------|-------------|-----------|----------|
| `sample_size` | Total sample size | Integer | Recommended |
| `year` | Publication year | Integer | Recommended |
| `quality_score` | Study quality score | Numeric | Optional |
| `subgroup` | Subgroup category | String | Optional |
| `ci_lower` | Lower confidence interval | Numeric | Optional |
| `ci_upper` | Upper confidence interval | Numeric | Optional |

## Effect Size Calculation Data

Instead of providing pre-calculated effect sizes, you can provide raw data and let the system calculate effect sizes for you. The required columns depend on the effect measure.

### Binary Outcomes (OR, RR)

For odds ratios (OR) or risk ratios (RR):
| Column | Description | Data Type | Required |
|--------|-------------|-----------|----------|
| `study` | Study identifier | String | Yes |
| `events_treatment` | Number of events in treatment group | Integer | Yes |
| `n_treatment` | Total subjects in treatment group | Integer | Yes |
| `events_control` | Number of events in control group | Integer | Yes |
| `n_control` | Total subjects in control group | Integer | Yes |

### Continuous Outcomes (MD, SMD)

For mean difference (MD) or standardized mean difference (SMD):
| Column | Description | Data Type | Required |
|--------|-------------|-----------|----------|
| `study` | Study identifier | String | Yes |
| `mean_treatment` | Mean in treatment group | Numeric | Yes |
| `sd_treatment` | Standard deviation in treatment group | Numeric | Yes |
| `n_treatment` | Sample size in treatment group | Integer | Yes |
| `mean_control` | Mean in control group | Numeric | Yes |
| `sd_control` | Standard deviation in control group | Numeric | Yes |
| `n_control` | Sample size in control group | Integer | Yes |

### Hazard Ratio Data (HR)

For hazard ratios (HR):
| Column | Description | Data Type | Required |
|--------|-------------|-----------|----------|
| `study` | Study identifier | String | Yes |
| `log_hr` | Natural log of hazard ratio | Numeric | Yes |
| `se_log_hr` | Standard error of log HR | Numeric | Yes |

Alternatively:
| Column | Description | Data Type | Required |
|--------|-------------|-----------|----------|
| `study` | Study identifier | String | Yes |
| `hr` | Hazard ratio | Numeric | Yes |
| `ci_lower` | Lower 95% confidence interval | Numeric | Yes |
| `ci_upper` | Upper 95% confidence interval | Numeric | Yes |

## Sample CSV File

### Precalculated Effect Sizes

```csv
study,effect_size,variance,sample_size,year
Study_1,0.6,0.0625,200,2015
Study_2,0.67,0.1225,100,2017
Study_3,0.63,0.0484,300,2018
Study_4,0.5,0.2025,150,2019
Study_5,0.64,0.0784,240,2020
```

### Binary Outcome Data (For OR Calculations)

```csv
study,events_treatment,n_treatment,events_control,n_control,year
Study_1,15,100,25,100,2015
Study_2,8,50,12,50,2017
Study_3,22,150,35,150,2018
Study_4,5,75,10,75,2019
Study_5,18,120,28,120,2020
```

### Continuous Outcome Data (For MD/SMD Calculations)

```csv
study,mean_treatment,sd_treatment,n_treatment,mean_control,sd_control,n_control,year
Study_1,12.5,3.2,50,10.2,3.0,50,2015
Study_2,15.3,4.1,60,11.8,3.9,60,2017
Study_3,14.2,2.8,75,10.5,2.9,75,2018
Study_4,13.7,3.5,40,11.2,3.3,40,2019
Study_5,15.1,3.9,55,12.4,3.7,55,2020
```

## Data Import Process

### Upload Process

1. Prepare your data according to the formats above
2. Save as a CSV file with UTF-8 encoding
3. Upload through the `upload_study_data` MCP tool
4. The system will validate the data structure

### Validation Levels

Two validation levels are supported:

#### Basic Validation
- Checks required columns exist
- Validates data types
- Ensures no missing values in required fields

#### Comprehensive Validation
- All basic validation checks
- Outlier detection
- Consistency checks (e.g., events cannot exceed sample sizes)
- Statistical reasonableness checks
- Missing data analysis
- Data range validation

## Common Data Issues

### Missing Data
- Missing values in optional fields are acceptable
- Missing values in required fields will cause validation failure
- Use clear designations for missing data (prefer empty cells over 0 or placeholders)

### Data Types
- Numeric columns should contain only numbers
- Avoid commas in numeric values (use 1000 not 1,000)
- Use period as decimal separator (use 10.5 not 10,5)

### Study Identifiers
- Each study must have a unique identifier
- Avoid special characters in study identifiers
- If a study appears multiple times (e.g., multiple outcomes), append a suffix (Study_1a, Study_1b)

### Effect Sizes

- Ensure effect sizes are on the correct scale:
  - OR, RR, HR: ratio measures (typically > 0)
  - MD, SMD: difference measures (can be positive or negative)
- Log-transform ratio measures if needed for normality

## Troubleshooting Data Issues

### Common Validation Errors

1. **"Missing required columns"**
   - Solution: Add the required columns to your CSV file

2. **"Invalid data type in column"**
   - Solution: Check for non-numeric values in numeric columns

3. **"Events exceed sample size"**
   - Solution: Verify that events_treatment ≤ n_treatment and events_control ≤ n_control

4. **"Invalid effect size"**
   - Solution: Check for implausible values or wrong scale/transformation

5. **"Zero or negative variance"**
   - Solution: Ensure all variance values are positive

### Recommended Data Preparation Tools

- **R**: Use `metafor::escalc()` to calculate effect sizes
- **Excel**: Templates available in the `templates` directory
- **Stata**: Use `metan` package for effect size calculations

## Advanced Data Topics

### Subgroup Analyses
Include a `subgroup` column to enable subgroup analyses:
```csv
study,effect_size,variance,subgroup
Study_1,0.6,0.0625,Group_A
Study_2,0.67,0.1225,Group_A
Study_3,0.63,0.0484,Group_B
Study_4,0.5,0.2025,Group_B
```

### Multiple Outcomes
For studies with multiple outcomes, create separate rows with unique study IDs:
```csv
study,effect_size,variance,outcome
Study_1a,0.6,0.0625,Mortality
Study_1b,0.8,0.09,Readmission
Study_2a,0.67,0.1225,Mortality
Study_2b,0.75,0.15,Readmission
```

### Multivariate Meta-Analysis
For advanced users needing multivariate meta-analysis, provide correlation between outcomes:
```csv
study,outcome,effect_size,variance,correlation
Study_1,Outcome_A,0.6,0.0625,1.0
Study_1,Outcome_B,0.8,0.09,0.5
Study_2,Outcome_A,0.67,0.1225,1.0
Study_2,Outcome_B,0.75,0.15,0.5
```

## References

For more information on calculating appropriate effect sizes:

- [Cochrane Handbook, Chapter 6: Choosing Effect Measures](https://training.cochrane.org/handbook/current/chapter-06)
- [Introduction to Meta-Analysis](https://www.meta-analysis.com/)
- [metafor package vignette](https://www.metafor-project.org/doku.php/tutorials)