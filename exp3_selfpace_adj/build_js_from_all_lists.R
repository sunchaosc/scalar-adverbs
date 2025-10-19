suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(jsonlite)
  library(stringr)
  library(tidyr)
  library(purrr)
  library(tools)
})

# ------------------------------------------------------------
# Args:
#   inpath       : path to ALL_lists.csv  (file)
#   outdir       : output folder for JS
#   practice_csv : path to practice/practice_trials.csv (file)
# ------------------------------------------------------------
args <- commandArgs(trailingOnly = TRUE)

# DEFAULTS:
# - If you keep ALL_lists.csv inside your OneDrive/lists_out folder, point directly to it.
inpath_default <- file.path(
  "/Users/chaosun/Library/CloudStorage/OneDrive-UniversityCollegeLondon/Projects/scalar-adverbs/scalar-adverbs/exp3_selfpace_adj/lists_out",
  "ALL_lists.csv"
)
practice_default <- "practice/practice_trials.csv"

inpath       <- ifelse(length(args) >= 1, args[1], inpath_default)
outdir       <- ifelse(length(args) >= 2, args[2], "js_out")
practice_csv <- ifelse(length(args) >= 3, args[3], practice_default)

dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

# ------------------ constants & helpers ---------------------
aoi_map <- c("LT"="AOI1","LB"="AOI2","RT"="AOI3","RB"="AOI4")
strip_png <- function(x) sub("\\.png$", "", x)

required_cols <- c(
  "list_id","display_id","condition","adj","instruction",
  "lt","lb","rt","rb","target_loc","competitor_loc","trial_in_list"
)

norm_colnames <- function(df) {
  nm <- names(df) |>
    trimws() |>
    tolower() |>
    gsub("\\s+","_", x = _) |>
    gsub("\\.+$", "", x = _)
  names(df) <- nm
  df
}

read_and_check <- function(csv_path, who="main") {
  if (!file.exists(csv_path)) stop(sprintf("File not found: %s", csv_path), call. = FALSE)
  df <- suppressMessages(read_csv(csv_path, show_col_types = FALSE))
  df <- norm_colnames(df)
  
  if (who == "practice") {
    # Practice can be minimal; add missing optional fields
    if (!"list_id" %in% names(df)) df$list_id <- NA_integer_
    if (!"trial_in_list" %in% names(df)) df$trial_in_list <- NA_integer_
    req_prac <- c("display_id","condition","adj","instruction","lt","lb","rt","rb","target_loc","competitor_loc")
    missing <- setdiff(req_prac, names(df))
    if (length(missing)) stop(sprintf("Practice CSV missing: %s", paste(missing, collapse=", ")), call. = FALSE)
  } else {
    missing <- setdiff(required_cols, names(df))
    if (length(missing)) stop(sprintf("Main CSV missing: %s", paste(missing, collapse=", ")), call. = FALSE)
  }
  df
}

to_js_rows <- function(df, is_practice = FALSE) {
  df <- df %>% rename(csv_condition = condition, csv_adj = adj)
  
  out <- df %>%
    transmute(
      displayID     = as.character(.data[["display_id"]]),
      location1     = strip_png(.data[["lt"]]),
      location2     = strip_png(.data[["lb"]]),
      location3     = strip_png(.data[["rt"]]),
      location4     = strip_png(.data[["rb"]]),
      target        = recode(as.character(.data[["target_loc"]]),     !!!aoi_map, .default = as.character(.data[["target_loc"]])),
      competitor    = recode(as.character(.data[["competitor_loc"]]), !!!aoi_map, .default = as.character(.data[["competitor_loc"]])),
      condition     = as.character(.data[["csv_adj"]]),                 # adjective / degree
      ExpFiller     = if (is_practice) "prac" else as.character(.data[["csv_condition"]]),
      correctAns    = recode(as.character(.data[["target_loc"]]), !!!aoi_map, .default = as.character(.data[["target_loc"]])),
      list          = if (is_practice) "practice" else as.character(.data[["list_id"]]),
      !!(if (is_practice) "instruction1" else "instruction3") := as.character(.data[["instruction"]]),
      trial_in_list = if (is_practice) NA_character_ else as.character(.data[["trial_in_list"]])
    )
  out
}

json_to_js_obj <- function(df) {
  js_text <- toJSON(df, auto_unbox = TRUE, pretty = TRUE)
  gsub('"([A-Za-z0-9_]+)"\\s*:', '\\1:', js_text)
}

# ------------------ read inputs -----------------------------
main_all <- read_and_check(inpath, who="main")
practice_df <- read_and_check(practice_csv, who="practice")

# One practice block for all outputs
practice_rows <- to_js_rows(practice_df, is_practice = TRUE)
practice_js_block <- paste0("exp.practice = ", json_to_js_obj(practice_rows), ";\n")

# Ensure we have 4 lists in the main CSV
list_ids <- sort(unique(main_all$list_id))
if (!length(list_ids)) stop("No list_id values found in main CSV.", call. = FALSE)

# ------------------ write four JS files ---------------------
for (L in list_ids) {
  dfL <- main_all %>% filter(list_id == L) %>% arrange(trial_in_list, display_id)
  
  stims_rows <- to_js_rows(dfL, is_practice = FALSE)
  stims_js <- paste0("exp.stims = ", json_to_js_obj(stims_rows), ";\n")
  
  js_out <- file.path(outdir, sprintf("stimuli_List%d.js", as.integer(L)))
  unlink(js_out)
  
  # Write: practice first, stims second
  writeLines(practice_js_block, js_out)
  cat(stims_js, file = js_out, append = TRUE)
  
  message(sprintf("Wrote %s (practice %d trials, list %d stims %d trials).",
                  js_out, nrow(practice_rows), as.integer(L), nrow(stims_rows)))
}

message("\nInclude ONE of the emitted files before index.js, e.g.:")
message('  <script src="js_out/stimuli_List1.js"></script>')
message('  <script src="index.js"></script>')
