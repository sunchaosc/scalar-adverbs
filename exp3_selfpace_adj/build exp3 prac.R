# ================= Practice Trials Generator (balanced v2) =================
# Output: ./practice/practice_trials.csv
# 4 trials total:
#  - EXP: boiling (100) & freezing (0); one SAME, one FLIP; different colors
#  - NUMBER: 60 & 0; one SAME, one FLIP; different colors
#  - 2 beaker targets + 2 flask targets total
#  - all three colors used; one repeats
#  - target corners: LT, RT, LB, RB exactly once
# ==========================================================================

suppressPackageStartupMessages({ library(dplyr) })

# ---- vocab ----
color_word <- c(o="orange", g="green", p="purple")
img_name <- function(obj, temp, col_letter) paste0(obj, "-", temp, "-", color_word[[col_letter]], ".png")
parse_img <- function(img) {
  s <- strsplit(gsub("\\.png$","", img), "-", TRUE)[[1]]
  list(object=s[1], temp=s[2], color_word=s[3])
}
clr_letter <- function(w) names(color_word)[match(w, color_word)]

# EXP and NUMBER target/competitor temperature mappings
exp_map <- list(
  boiling  = list(tar="hot",  comp="warm", degree = 100),
  freezing = list(tar="cold", comp="cool", degree = 0)
)
num_map <- list(
  `60` = list(tar="warm", comp="hot"),
  `10` = list(tar="cool", comp="cold"), 
  `0`  = list(tar="cold", comp="cool")
)

# sentence builders (pipes exact)
sent_exp <- function(obj, adj, col) paste0("The water | in the ", obj, " | is ", adj, " | and ", color_word[[col]], ".")
sent_num <- function(obj, deg, col) paste0("The water | in the ", obj, " | is about ", deg, " degree| and ", color_word[[col]], ".")

# Place 4 images on grid given a target position
place_images <- function(target_img, competitor_img, horiz_img, other_img, target_pos) {
  all <- c("LT","RT","LB","RB")
  stopifnot(target_pos %in% all)
  vm <- list(LT="LB", LB="LT", RT="RB", RB="RT")
  hm <- list(LT="RT", RT="LT", LB="RB", RB="LB")
  out <- c(LT=NA_character_, RT=NA_character_, LB=NA_character_, RB=NA_character_)
  out[target_pos] <- target_img
  out[vm[[target_pos]]]  <- competitor_img
  out[hm[[target_pos]]]  <- horiz_img
  out[setdiff(all, names(out[!is.na(out)]))] <- other_img
  out
}
add_locs <- function(df) {
  find_loc <- function(row_imgs, img) {
    if (is.na(img)) return(NA_character_)
    hit <- which(row_imgs == img)
    if (length(hit)) names(row_imgs)[hit[1]] else NA_character_
  }
  df$target_loc <- vapply(seq_len(nrow(df)), function(i)
    find_loc(df[i, c("LT","RT","LB","RB")], df$target_image[i]), character(1))
  df$competitor_loc <- vapply(seq_len(nrow(df)), function(i)
    find_loc(df[i, c("LT","RT","LB","RB")], df$competitor_image[i]), character(1))
  df
}

# Build a SAME/FLIP display set given a color pair "x-y" and temps
# SAME: beaker & flask target color = first (x)
# FLIP: beaker target color = first (x), flask target color = second (y)
build_sameflip_images <- function(pair, tT, tC, flip=FALSE) {
  cols <- strsplit(pair, "-", TRUE)[[1]]
  b1 <- img_name("beaker", tT, cols[1]); b2 <- img_name("beaker", tC, cols[2])
  if (!flip) {
    f1 <- img_name("flask",  tT, cols[1]); f2 <- img_name("flask",  tC, cols[2])
  } else {
    f1 <- img_name("flask",  tT, cols[2]); f2 <- img_name("flask",  tC, cols[1])
  }
  c(b1=b1, b2=b2, f1=f1, f2=f2)
}

# -------------------- Design for 4 practice trials --------------------
# We ensure: 2 beaker, 2 flask targets; one SAME + one FLIP in EXP and NUMBER;
# EXP colors differ; NUMBER colors differ; overall 3 colors with one repeated;
# corners LT/RT/LB/RB exactly once.

plan <- list(
  # 1) EXP: boiling (degree=100), SAME, target = beaker, color = orange, corner LT
  list(
    condition="exp", adj="boiling", degree=exp_map$boiling$degree,
    spec=exp_map$boiling, pair="o-g", flip=FALSE,
    target_object="beaker", force_color="o", target_pos="LT"
  ),
  # 2) EXP: freezing (degree=0), FLIP, target = flask, color = green, corner RT
  #   Use pair "o-g" so FLIP makes flask target = second color ("g")
  list(
    condition="exp", adj="freezing", degree=exp_map$freezing$degree,
    spec=exp_map$freezing, pair="o-g", flip=TRUE,
    target_object="flask",  force_color="g", target_pos="RT"
  ),
  # 3) NUMBER: 60, SAME, target = flask, color = purple, corner LB
  #   SAME ⇒ both objects target color = first of pair ("p")
  list(
    condition="number", adj="60", degree=60,
    spec=num_map[["60"]], pair="p-g", flip=FALSE,
    target_object="flask", force_color="p", target_pos="LB"
  ),
  # 4) NUMBER: 0, FLIP, target = beaker, color = orange, corner RB
  #   FLIP ⇒ beaker target = first of pair ("o")
  # 4) NUMBER: 10, FLIP, target = beaker, color = orange, corner RB
  #   Mapping: 10 ⇒ target=cool, competitor=cold; FLIP keeps beaker target = first color ("o")
  list(
    condition="number", adj="10", degree=10,
    spec=num_map[["10"]], pair="o-g", flip=TRUE,
    target_object="beaker", force_color="o", target_pos="RB"
  )
  
)

rows <- list(); k <- 1L
for (i in seq_along(plan)) {
  P <- plan[[i]]
  imgs <- build_sameflip_images(P$pair, tT=P$spec$tar, tC=P$spec$comp, flip=P$flip)
  
  # pick target image based on requested target_object
  if (P$target_object == "beaker") {
    tgti <- if (grepl(paste0("-",P$spec$tar,"-"), imgs["b1"])) imgs["b1"] else imgs["b2"]
    cmpi <- if (tgti==imgs["b1"]) imgs["b2"] else imgs["b1"]
    horiz <- imgs["f1"]; other <- imgs["f2"]
  } else {
    tgti <- if (grepl(paste0("-",P$spec$tar,"-"), imgs["f1"])) imgs["f1"] else imgs["f2"]
    cmpi <- if (tgti==imgs["f1"]) imgs["f2"] else imgs["f1"]
    horiz <- imgs["b1"]; other <- imgs["b2"]
  }
  
  # safety: color matches the requested one
  tgt <- parse_img(tgti); col_letter <- clr_letter(tgt$color_word)
  if (col_letter != P$force_color)
    stop(sprintf("Trial %d color mismatch: got %s, wanted %s", i, col_letter, P$force_color))
  
  # sentence & instruction (pipes exact), degrees filled even for EXP per your note
  if (P$condition == "exp") {
    s <- sent_exp(P$target_object, P$adj, col_letter)
  } else {
    s <- sent_num(P$target_object, P$degree, col_letter)
  }
  
  lay <- place_images(tgti, cmpi, horiz, other, target_pos=P$target_pos)
  
  rows[[k]] <- data.frame(
    display_id = i,                         # 1..4 within the practice file
    condition = P$condition,
    target_object = P$target_object,
    adj = if (P$condition=="exp") P$adj else as.character(P$adj),
    degree = as.integer(P$degree),          # EXP: boiling=100, freezing=0; NUMBER: 60/0
    target_image = tgti,
    competitor_image = cmpi,
    other1_image = horiz,
    other2_image = other,
    LT = lay["LT"], RT = lay["RT"], LB = lay["LB"], RB = lay["RB"],
    mentioned_color = col_letter,
    mentioned_color_word = tgt$color_word,
    sentence = s,
    instruction = s,
    stringsAsFactors = FALSE
  )
  k <- k+1L
}

df <- dplyr::bind_rows(rows)

# --- Checks ---
# 2 beaker, 2 flask
stopifnot(all(table(df$target_object) == c(beaker=2, flask=2)))
# EXP colors differ
stopifnot(length(unique(df$mentioned_color[df$condition=="exp"])) == 2)
# NUMBER colors differ
stopifnot(length(unique(df$mentioned_color[df$condition=="number"])) == 2)
# All three colors used; one repeats
tabc <- table(df$mentioned_color); stopifnot(length(tabc)==3 && any(tabc==2) && all(tabc>=1))
# Corners once each
# derive target_loc
df <- df %>% add_locs()
stopifnot(all(sort(df$target_loc) == c("LB","LT","RB","RT")))

# --- Write CSV ---
dir.create("practice", showWarnings = FALSE, recursive = TRUE)
write.csv(df, file.path("practice","practice_trials.csv"), row.names = FALSE)

cat("Practice trials written to ./practice/practice_trials.csv\n")
