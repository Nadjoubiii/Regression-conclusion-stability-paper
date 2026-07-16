## Import the classic diabetes benchmark dataset and save a raw copy for analysis.

if (!requireNamespace("lars", quietly = TRUE)) {
	stop("Package 'lars' is required. Install it before running this script.")
}

out_dir <- file.path("data", "raw")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

suppressPackageStartupMessages(library(lars))
data("diabetes", package = "lars")

diabetes_data <- get("diabetes")

if (is.data.frame(diabetes_data)) {
	# Keep data frames as-is.
} else if (is.list(diabetes_data) && all(c("x", "y") %in% names(diabetes_data))) {
	predictors <- as.data.frame(diabetes_data$x)
	if (is.null(colnames(predictors))) {
		colnames(predictors) <- paste0("x", seq_len(ncol(predictors)))
	}
	diabetes_data <- data.frame(y = diabetes_data$y, predictors, row.names = NULL)
} else if (exists("diabetes.x") && exists("diabetes.y")) {
	predictors <- as.data.frame(get("diabetes.x"))
	if (is.null(colnames(predictors))) {
		colnames(predictors) <- paste0("x", seq_len(ncol(predictors)))
	}
	diabetes_data <- data.frame(y = get("diabetes.y"), predictors, row.names = NULL)
} else {
	stop("Could not recognize the structure of the diabetes dataset from lars.")
}

saveRDS(diabetes_data, file.path(out_dir, "diabetes_raw.rds"))
write.csv(diabetes_data, file.path(out_dir, "diabetes_raw.csv"), row.names = FALSE)

message(sprintf("Saved diabetes data: %d rows, %d columns", nrow(diabetes_data), ncol(diabetes_data)))