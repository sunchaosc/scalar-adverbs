library(dplyr)
library(tidyr)
library(stringr)
library(purrr)

# Compare the same list (e.g., "List1") across V1, V2, V3
compare_list_across_variants <- function(lists_V1, lists_V2, lists_V3, list_name = "List1") {
  # pull the three data frames
  v1 <- lists_V1[[list_name]] %>% mutate(variant = "V1")
  v2 <- lists_V2[[list_name]] %>% mutate(variant = "V2")
  v3 <- lists_V3[[list_name]] %>% mutate(variant = "V3")
  
  # a "trial identity" that ignores placement but keeps conceptual content
  key_cols <- c("display_id", "target_object", "modal", "condition",
                "target_image", "competitor_image", "other1_image", "other2_image")
  
  # keep only needed columns (+ placements and a simple row id)
  cols_keep <- c(key_cols, "LT","RT","LB","RB","variant")
  
  v1 <- v1 %>% select(any_of(cols_keep))
  v2 <- v2 %>% select(any_of(cols_keep))
  v3 <- v3 %>% select(any_of(cols_keep))
  
  # Bind all variants together
  allv <- bind_rows(v1, v2, v3) %>%
    mutate(trial_key = paste(display_id, target_object, modal, condition,
                             target_image, competitor_image, other1_image, other2_image, sep = " | "))
  
  # ---- (A) EXP/FILLER assignment diffs across variants ----
  # If the same trial_key is exp in one variant and filler in another, flag it
  assign_wide <- allv %>%
    select(variant, trial_key, condition) %>%
    distinct() %>%
    pivot_wider(names_from = variant, values_from = condition)
  
  assignment_diffs <- assign_wide %>%
    filter(!(V1 == V2 & V2 == V3)) %>%
    left_join(allv %>% select(trial_key, all_of(key_cols)) %>% distinct(), by = "trial_key") %>%
    relocate(trial_key, V1, V2, V3)
  
  # ---- (B) Placement-only diffs (same assignment everywhere, LT/RT/LB/RB differ) ----
  # Keep trials present in ALL variants with same condition
  common_trials <- assign_wide %>%
    filter(!is.na(V1) & !is.na(V2) & !is.na(V3)) %>%         # present in all three
    filter(V1 == V2 & V2 == V3) %>%                           # same assignment everywhere
    pull(trial_key)
  
  # Function to collect placements per trial_key per variant
  placements <- allv %>%
    filter(trial_key %in% common_trials) %>%
    select(trial_key, variant, LT, RT, LB, RB)
  
  # Reshape so each variant's placements are side-by-side
  place_wide <- placements %>%
    pivot_longer(cols = c(LT, RT, LB, RB), names_to = "pos", values_to = "img") %>%
    unite(var_pos, variant, pos) %>%
    pivot_wider(names_from = var_pos, values_from = img)
  
  # Compare placements across variants
  placement_diffs <- place_wide %>%
    mutate(
      same_V1_V2 = (V1_LT == V2_LT) & (V1_RT == V2_RT) & (V1_LB == V2_LB) & (V1_RB == V2_RB),
      same_V2_V3 = (V2_LT == V3_LT) & (V2_RT == V3_RT) & (V2_LB == V3_LB) & (V2_RB == V3_RB),
      same_V1_V3 = (V1_LT == V3_LT) & (V1_RT == V3_RT) & (V1_LB == V3_LB) & (V1_RB == V3_RB),
      any_diff   = !(same_V1_V2 & same_V2_V3 & same_V1_V3)
    ) %>%
    filter(any_diff) %>%
    select(trial_key, starts_with("V1_"), starts_with("V2_"), starts_with("V3_")) %>%
    left_join(allv %>% select(trial_key, all_of(key_cols)) %>% distinct(), by = "trial_key") %>%
    relocate(trial_key, display_id, target_object, modal, condition)
  
  # ---- quick summary counts ----
  summary <- list(
    n_trials_V1 = nrow(v1),
    n_trials_V2 = nrow(v2),
    n_trials_V3 = nrow(v3),
    n_assignment_diffs = nrow(assignment_diffs),
    n_placement_diffs  = nrow(placement_diffs)
  )
  
  list(
    summary = summary,
    assignment_differences = assignment_diffs,
    placement_only_differences = placement_diffs
  )
}

# Example usage:
res_L1 <- compare_list_across_variants(lists_V1, lists_V2, lists_V3, list_name = "List4")
res_L1$summary
# View assignment differences:
 View(res_L1$assignment_differences)
# View placement-only differences:
 View(res_L1$placement_only_differences)
 

 library(dplyr)
 library(tidyr)
 
 # Summarize condition per (display_id, target_object) for one list/variant
 summarize_assignments <- function(df, variant_name) {
   df %>%
     group_by(display_id, target_object) %>%
     summarize(
       condition = dplyr::case_when(
         any(condition == "exp", na.rm = TRUE)    ~ "exp",
         any(condition == "filler", na.rm = TRUE) ~ "filler",
         TRUE                                     ~ NA_character_
       ),
       .groups = "drop"
     ) %>%
     mutate(variant = variant_name)
 }
 
 # Compare the same list across V1, V2, V3 by (display_id, target_object)
 compare_assignments_by_display <- function(lists_V1, lists_V2, lists_V3, list_name = "List4") {
   v1 <- summarize_assignments(lists_V1[[list_name]], "V1")
   v2 <- summarize_assignments(lists_V2[[list_name]], "V2")
   v3 <- summarize_assignments(lists_V3[[list_name]], "V3")
   
   wide <- bind_rows(v1, v2, v3) %>%
     select(variant, display_id, target_object, condition) %>%
     pivot_wider(names_from = variant, values_from = condition)
   
   # keep only rows where at least one variant differs
   diffs <- wide %>% filter(!(V1 == V2 & V2 == V3))
   
   list(
     summary = list(
       n_pairs_checked = nrow(wide),
       n_differences   = nrow(diffs)
     ),
     differences = diffs
   )
 }
 
 # Example usage:
  res <- compare_assignments_by_display(lists_V1, lists_V2, lists_V3, list_name = "List4")
 print(res$summary)
 print(res$differences)
