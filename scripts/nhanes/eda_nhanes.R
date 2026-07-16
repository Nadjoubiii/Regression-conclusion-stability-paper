# Exploratory data analysis for NHANES.

out_dir <- file.path("results", "nhanes_eda")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

raw_path_rds <- file.path("data", "raw", "nhanes_raw.rds")
raw_path_csv <- file.path("data", "raw", "nhanes_raw.csv")

if (file.exists(raw_path_rds)) {
	nhanes <- readRDS(raw_path_rds)
} else if (file.exists(raw_path_csv)) {
	nhanes <- read.csv(raw_path_csv)
} else {
	stop("NHANES raw data not found. Run scripts/nhanes/import_nhanes.R first.")
}

key_vars <- c(
	"Age",
	"Gender",
	"Race1",
	"Education",
	"HHIncomeMid",
	"Poverty",
	"BMI",
	"BPSysAve",
	"BPDiaAve",
	"DirectChol",
	"TotChol",
	"Diabetes"
)

available_vars <- intersect(key_vars, names(nhanes))
eda_data <- nhanes[, available_vars, drop = FALSE]

summary_lines <- c(
	"NHANES EDA",
	"===========",
	"")
summary_lines <- c(summary_lines, sprintf("Rows: %d", nrow(nhanes)))
summary_lines <- c(summary_lines, sprintf("Columns: %d", ncol(nhanes)))
summary_lines <- c(summary_lines, sprintf("Key variables available: %d of %d", length(available_vars), length(key_vars)))
summary_lines <- c(summary_lines, "")
summary_lines <- c(summary_lines, "Variable missingness:")
summary_lines <- c(summary_lines, capture.output(sort(colSums(is.na(eda_data)), decreasing = TRUE)))

writeLines(summary_lines, file.path(out_dir, "nhanes_summary.txt"))
write.csv(
	data.frame(
		variable = names(eda_data),
		missing = colSums(is.na(eda_data)),
		missing_rate = colMeans(is.na(eda_data))
	),
	file.path(out_dir, "nhanes_missingness.csv"),
	row.names = FALSE
)

numeric_vars <- names(eda_data)[vapply(eda_data, is.numeric, logical(1))]
numeric_summary <- do.call(rbind, lapply(numeric_vars, function(var_name) {
	values <- eda_data[[var_name]]
	data.frame(
		variable = var_name,
		n = sum(!is.na(values)),
		mean = mean(values, na.rm = TRUE),
		sd = sd(values, na.rm = TRUE),
		median = median(values, na.rm = TRUE),
		min = min(values, na.rm = TRUE),
		max = max(values, na.rm = TRUE),
		stringsAsFactors = FALSE
	)
}))
write.csv(numeric_summary, file.path(out_dir, "nhanes_numeric_summary.csv"), row.names = FALSE)

categorical_vars <- names(eda_data)[vapply(eda_data, function(x) is.character(x) || is.factor(x), logical(1))]
for (var_name in categorical_vars) {
	counts <- sort(table(eda_data[[var_name]], useNA = "ifany"), decreasing = TRUE)
	write.csv(
		data.frame(level = names(counts), count = as.integer(counts), stringsAsFactors = FALSE),
		file.path(out_dir, paste0("nhanes_", tolower(var_name), "_counts.csv")),
		row.names = FALSE
	)
}

png(file.path(out_dir, "nhanes_age_hist.png"), width = 900, height = 650)
hist(nhanes$Age, breaks = 25, col = "gray70", border = "white", main = "NHANES Age Distribution", xlab = "Age")
dev.off()

png(file.path(out_dir, "nhanes_bmi_hist.png"), width = 900, height = 650)
hist(nhanes$BMI, breaks = 25, col = "steelblue3", border = "white", main = "NHANES BMI Distribution", xlab = "BMI")
dev.off()

png(file.path(out_dir, "nhanes_bmi_by_gender.png"), width = 900, height = 650)
boxplot(BMI ~ Gender, data = nhanes, col = "tan", main = "BMI by Gender", xlab = "Gender", ylab = "BMI")
dev.off()

png(file.path(out_dir, "nhanes_bmi_by_diabetes.png"), width = 900, height = 650)
boxplot(BMI ~ Diabetes, data = nhanes, col = "plum2", main = "BMI by Diabetes Status", xlab = "Diabetes", ylab = "BMI")
dev.off()

png(file.path(out_dir, "nhanes_age_bmi_scatter.png"), width = 900, height = 650)
plot(nhanes$Age, nhanes$BMI, pch = 19, cex = 0.5, col = rgb(0, 0, 0, 0.2), main = "Age vs BMI", xlab = "Age", ylab = "BMI")
dev.off()

message(sprintf("Saved NHANES EDA outputs to %s", out_dir))