## Import the NHANES dataset and save a raw copy for analysis.

if (!requireNamespace("NHANES", quietly = TRUE)) {
	stop("Package 'NHANES' is required. Install it before running this script.")
}

out_dir <- file.path("data", "raw")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

nhanes_data <- NHANES::NHANES

saveRDS(nhanes_data, file.path(out_dir, "nhanes_raw.rds"))
write.csv(nhanes_data, file.path(out_dir, "nhanes_raw.csv"), row.names = FALSE)

message(sprintf("Saved NHANES data: %d rows, %d columns", nrow(nhanes_data), ncol(nhanes_data)))