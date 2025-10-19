# ==========================================================
# Follow-up list generator (spec v9)
# Each list: 16 EXP + 8 NUMBER + 8 TYPE-B = 32 trials
# Displays: EXP+NUMBER use exactly 12 unique displays (IDs 1..12), each used twice
#           TYPE-B uses exactly 8 displays (IDs 13..20)
# Objects: beaker, flask
# Colors: o=orange, g=green, p=purple
# File temps: warm, hot, cool, cold
# EXP adjectives (adj): warm, boiling, cool, freezing
# Degrees (NUMBER & TYPE-B): 0, 10, 60, 100
# Guarantees (per list):
#   - EXP per adjective: 4 trials, covering all 3 colors (one repeats), via 2 SAME + 2 FLIP
#   - NUMBER per degree: 2 trials (1 SAME + 1 FLIP), target colors differ
#   - EXP+NUMBER color balance: orange=8, green=8, purple=8 (asserted)
#   - Each of the 12 (IDs 1..12) used exactly twice (beaker target + flask target)
#   - TYPE-B IDs 13..20; per list color usage is a (3,3,2) split, rotated across lists
#   - TYPE-B per degree: 2 trials; colors differ
#   - Target positions across all 32 trials: LT/RT/LB/RB = 8 each
#   - No color_pair column
# Pipes exact in sentences/instructions.
# ==========================================================

suppressPackageStartupMessages({ library(dplyr); library(stringr) })
set.seed(20251017)

# ---------- vocab ----------
color_word <- c(o="orange", g="green", p="purple")
temp2adj <- c(warm="warm", hot="boiling", cool="cool", cold="freezing")
adj2deg  <- c(warm=60, boiling=100, cool=10, freezing=0)
deg2ft   <- c(`0`="cold", `10`="cool", `60`="warm", `100`="hot")

img_name <- function(obj, ft, c) paste0(obj,"-",ft,"-",color_word[[c]],".png")
parse_img <- function(img) { s <- strsplit(sub("\\.png$","",img), "-", TRUE)[[1]]; list(object=s[1], ft=s[2], color_word=s[3]) }
clr_letter <- function(w) names(color_word)[match(w, color_word)]

# ---------- placement ----------
place_images <- function(target_img, competitor_img, horiz_img, other_img, target_pos) {
  all <- c("LT","RT","LB","RB"); stopifnot(target_pos %in% all)
  vm <- list(LT="LB", LB="LT", RT="RB", RB="RT")
  hm <- list(LT="RT", RT="LT", LB="RB", RB="LB")
  out <- c(LT=NA, RT=NA, LB=NA, RB=NA)
  out[target_pos] <- target_img
  out[vm[[target_pos]]] <- competitor_img
  out[hm[[target_pos]]] <- horiz_img
  out[setdiff(all, names(out[!is.na(out)]))] <- other_img
  out
}
assign_balanced_positions_32 <- function(df) {
  stopifnot(nrow(df)==32)
  pos <- rep(c("LT","RT","LB","RB"), each=8)
  pos <- sample(pos)
  for (i in seq_len(nrow(df))) {
    lay <- place_images(df$target_image[i], df$competitor_image[i],
                        df$other1_image[i], df$other2_image[i], pos[i])
    df$LT[i] <- lay["LT"]; df$RT[i] <- lay["RT"]; df$LB[i] <- lay["LB"]; df$RB[i] <- lay["RB"]
  }
  df
}
add_target_comp_loc <- function(df) {
  find_loc <- function(row_imgs, img) {
    if (is.na(img)) return(NA_character_)
    hit <- which(row_imgs==img)
    if (length(hit)) names(row_imgs)[hit[1]] else NA_character_
  }
  df$target_loc <- vapply(seq_len(nrow(df)), function(i)
    find_loc(df[i, c("LT","RT","LB","RB")], df$target_image[i]), character(1))
  df$competitor_loc <- vapply(seq_len(nrow(df)), function(i)
    find_loc(df[i, c("LT","RT","LB","RB")], df$competitor_image[i]), character(1))
  df
}

# ---------- mappings ----------
exp_map <- list(
  warm     = list(tar="warm", comp="hot"),
  boiling  = list(tar="hot",  comp="warm"),
  cool     = list(tar="cool", comp="cold"),
  freezing = list(tar="cold", comp="cool")
)
num_map <- list(
  `0`   = list(tar="cold", comp="cool"),
  `10`  = list(tar="cool", comp="cold"),
  `60`  = list(tar="warm", comp="hot"),
  `100` = list(tar="hot",  comp="warm")
)

# ---------- sentences (pipes exact) ----------
sent_exp <- function(obj, adj, col) paste0("The water | in the ", obj, " | is ", adj, " | and ", color_word[[col]], ".")
sent_num <- function(obj, deg, col) paste0("The water | in the ", obj, " | is about ", deg, " degree| and ", color_word[[col]], ".")

# ---------- display registry (global IDs) ----------
.make_sig <- function(imgs4) paste(sort(imgs4), collapse=" | ")
reg <- new.env(parent=emptyenv())
disp_ctr <- 0L
register_display <- function(imgs4, force_id=NULL) {
  sig <- .make_sig(imgs4)
  id <- reg[[sig]]
  if (is.null(id)) {
    if (is.null(force_id)) disp_ctr <<- disp_ctr + 1L else disp_ctr <<- force_id
    id <- disp_ctr
    reg[[sig]] <<- id
  }
  id
}

# ---------- low-level display builders ----------
# SAME or FLIP across objects (for EXP/NUMBER)
# pair "x-y": beaker target color x; SAME => flask target color x; FLIP => flask target color y
build_sameflip_display <- function(pair, tT, tC, flip=FALSE) {
  cols <- strsplit(pair, "-", TRUE)[[1]]
  b1 <- img_name("beaker", tT, cols[1]); b2 <- img_name("beaker", tC, cols[2])
  if (!flip) { f1 <- img_name("flask", tT, cols[1]); f2 <- img_name("flask", tC, cols[2]) }
  else       { f1 <- img_name("flask", tT, cols[2]); f2 <- img_name("flask", tC, cols[1]) }
  c(b1=b1, b2=b2, f1=f1, f2=f2)
}
# TYPE-B: within-object same temp; across objects same side
build_typeB_display <- function(pair, beaker_ft, flask_ft) {
  ok <- (beaker_ft %in% c("warm","hot")  && flask_ft %in% c("warm","hot")) ||
    (beaker_ft %in% c("cool","cold") && flask_ft %in% c("cool","cold"))
  stopifnot(ok)
  cols <- strsplit(pair, "-", TRUE)[[1]]
  b1 <- img_name("beaker", beaker_ft, cols[1]); b2 <- img_name("beaker", beaker_ft, cols[2])
  f1 <- img_name("flask",  flask_ft,  cols[1]); f2 <- img_name("flask",  flask_ft,  cols[2])
  c(b1=b1, b2=b2, f1=f1, f2=f2)
}

# ==========================================================
# 12 DISPLAYS for EXP+NUMBER (IDs 1..12) — reused in every list
#   EXP: 8 displays = 2 per adjective (SAME + FLIP) with color plan ensuring 3-color coverage
#   NUMBER: 4 displays = 1 per degree, with SAME+FLIP generated at trial time
# ==========================================================

# EXP color plan: for each adjective, SAME uses X (repeated), FLIP uses the other two (Y-Z)
exp_color_plan <- list(
  warm     = list(X="o", flip_pair="g-p"),
  boiling  = list(X="g", flip_pair="o-p"),
  cool     = list(X="p", flip_pair="o-g"),
  freezing = list(X="o", flip_pair="g-p")
)

build_12_displays <- function() {
  out <- list(); id <- 1L
  
  # 8 EXP displays (2 per adjective): SAME then FLIP
  for (adj in c("warm","boiling","cool","freezing")) {
    m <- exp_map[[adj]]; pl <- exp_color_plan[[adj]]
    
    # SAME display for adj (X repeated across objects)
    same_pair <- paste0(pl$X, "-", setdiff(c("o","g","p"), pl$X)[1])
    imgsS <- build_sameflip_display(same_pair, m$tar, m$comp, flip=FALSE)
    register_display(imgsS, force_id = id); out[[length(out)+1]] <- list(id=id, kind="EXP", adj=adj, flip=FALSE, imgs=imgsS); id <- id+1L
    
    # FLIP display for adj (two other colors)
    imgsF <- build_sameflip_display(pl$flip_pair, m$tar, m$comp, flip=TRUE)
    register_display(imgsF, force_id = id); out[[length(out)+1]] <- list(id=id, kind="EXP", adj=adj, flip=TRUE, imgs=imgsF); id <- id+1L
  }
  
  # 4 NUMBER displays (1 per degree) — we store one base FLIP-friendly display per degree
  # We will derive SAME and FLIP trials from these *same* displays (beaker & flask targets) so each display is used twice.
  num_pairs <- c(`0`="g-p", `10`="o-g", `60`="o-p", `100`="g-p")
  for (deg in c(0,10,60,100)) {
    m <- num_map[[as.character(deg)]]
    base_pair <- num_pairs[[as.character(deg)]]
    # Build a FLIP-style layout so that beaker=first color, flask=second color at target temp.
    imgs <- build_sameflip_display(base_pair, m$tar, m$comp, flip=TRUE)
    register_display(imgs, force_id = id); out[[length(out)+1]] <- list(id=id, kind="NUMBER", degree=deg, imgs=imgs); id <- id+1L
  }
  
  stopifnot(id==13L) # ensured 1..12 used
  out
}

# Trials from the 12 displays — each used exactly twice (beaker+flask)
make_expnum_trials_from_12 <- function(list_id, D12) {
  rows <- list(); k <- 1L
  
  # EXP: for each adjective we have two displays: SAME (both X) and FLIP (Y,Z)
  for (adj in c("warm","boiling","cool","freezing")) {
    spec <- exp_map[[adj]]
    d_same <- D12[[ which(sapply(D12, function(x) x$kind=="EXP" && x$adj==adj && !x$flip)) ]]
    d_flip <- D12[[ which(sapply(D12, function(x) x$kind=="EXP" && x$adj==adj &&  x$flip)) ]]
    
    for (d in list(d_same, d_flip)) {
      imgs <- d$imgs; disp_id <- d$id
      # Two trials: beaker target & flask target (so display used exactly twice)
      for (obj in c("beaker","flask")) {
        if (obj=="beaker") {
          tgti <- if (grepl(paste0("-",spec$tar,"-"), imgs["b1"])) imgs["b1"] else imgs["b2"]
          cmpi <- if (tgti==imgs["b1"]) imgs["b2"] else imgs["b1"]; horiz <- imgs["f1"]; other <- imgs["f2"]
        } else {
          tgti <- if (grepl(paste0("-",spec$tar,"-"), imgs["f1"])) imgs["f1"] else imgs["f2"]
          cmpi <- if (tgti==imgs["f1"]) imgs["f2"] else imgs["f1"]; horiz <- imgs["b1"]; other <- imgs["b2"]
        }
        tgt <- parse_img(tgti); col <- clr_letter(tgt$color_word)
        s <- sent_exp(obj, temp2adj[[tgt$ft]], col)
        lay <- place_images(tgti, cmpi, horiz, other, target_pos="LT")
        
        rows[[k]] <- data.frame(
          list_id=list_id, list_name=paste0("List",list_id),
          condition="exp", display_id=disp_id, target_object=obj,
          adj=temp2adj[[tgt$ft]], degree=adj2deg[[ temp2adj[[tgt$ft]] ]],
          target_image=tgti, competitor_image=cmpi, other1_image=horiz, other2_image=other,
          LT=lay["LT"], RT=lay["RT"], LB=lay["LB"], RB=lay["RB"],
          mentioned_color=col, mentioned_color_word=tgt$color_word,
          sentence=s, instruction=s, stringsAsFactors=FALSE
        ); k <- k+1L
      }
    }
  }
  
  # NUMBER: for each degree we have one display; again, two trials per display (beaker as SAME-color target, flask as FLIP-color target)
  for (deg in c(0,10,60,100)) {
    dN <- D12[[ which(sapply(D12, function(x) x$kind=="NUMBER" && x$degree==deg)) ]]
    spec <- num_map[[as.character(deg)]]
    imgs <- dN$imgs; disp_id <- dN$id
    
    # Trial 1 (beaker target): target color == first color of the stored pair
    tgti <- if (grepl(paste0("-",spec$tar,"-"), imgs["b1"])) imgs["b1"] else imgs["b2"]
    cmpi <- if (tgti==imgs["b1"]) imgs["b2"] else imgs["b1"]; horiz <- imgs["f1"]; other <- imgs["f2"]
    tgt <- parse_img(tgti); col <- clr_letter(tgt$color_word)
    s <- sent_num("beaker", deg, col)
    lay <- place_images(tgti, cmpi, horiz, other, target_pos="LT")
    rows[[k]] <- data.frame(
      list_id=list_id, list_name=paste0("List",list_id),
      condition="number", display_id=disp_id, target_object="beaker",
      adj=as.character(deg), degree=deg,
      target_image=tgti, competitor_image=cmpi, other1_image=horiz, other2_image=other,
      LT=lay["LT"], RT=lay["RT"], LB=lay["LB"], RB=lay["RB"],
      mentioned_color=clr_letter(tgt$color_word), mentioned_color_word=tgt$color_word,
      sentence=s, instruction=s, stringsAsFactors=FALSE
    ); k <- k+1L
    
    # Trial 2 (flask target): target color == second color of the stored pair (different color)
    tgti <- if (grepl(paste0("-",spec$tar,"-"), imgs["f2"])) imgs["f2"] else imgs["f1"]  # f2 carries second color at target temp in FLIP layout
    cmpi <- if (tgti==imgs["f2"]) imgs["f1"] else imgs["f2"]; horiz <- imgs["b1"]; other <- imgs["b2"]
    tgt <- parse_img(tgti); col <- clr_letter(tgt$color_word)
    s <- sent_num("flask", deg, col)
    lay <- place_images(tgti, cmpi, horiz, other, target_pos="LT")
    rows[[k]] <- data.frame(
      list_id=list_id, list_name=paste0("List",list_id),
      condition="number", display_id=disp_id, target_object="flask",
      adj=as.character(deg), degree=deg,
      target_image=tgti, competitor_image=cmpi, other1_image=horiz, other2_image=other,
      LT=lay["LT"], RT=lay["RT"], LB=lay["LB"], RB=lay["RB"],
      mentioned_color=clr_letter(tgt$color_word), mentioned_color_word=tgt$color_word,
      sentence=s, instruction=s, stringsAsFactors=FALSE
    ); k <- k+1L
  }
  
  df <- bind_rows(rows)
  
  # Sanity checks: 12 distinct display_id used, each exactly twice
  stopifnot(length(unique(df$display_id))==12)
  cts <- table(df$display_id); stopifnot(all(cts==2))
  
  # Color balance for EXP+NUMBER: must be 8/8/8
  tot <- table(df$mentioned_color_word)
  if (any(is.na(tot[c("orange","green","purple")]))) stop("Missing colors in EXP+NUMBER.")
  stopifnot(all(as.integer(tot[c("orange","green","purple")]) == c(8,8,8)))
  
  df
}

# ==========================================================
# TYPE-B DESIGNS (IDs 13..20) + per-list color split (3,3,2) rotated
# ==========================================================

build_typeB_designs <- function() {
  # Two displays per degree, kept same-side; choose pairs to give two different target colors
  plan <- list(
    `0`   = c("o-g","o-p"),
    `10`  = c("g-p","o-g"),
    `60`  = c("o-p","g-p"),
    `100` = c("o-g","o-p")
  )
  out <- list(); id <- 13L
  for (deg in c(0,10,60,100)) {
    base <- deg2ft[[as.character(deg)]]
    partner <- if (base %in% c("warm","hot")) if (base=="warm") "hot" else "warm"
    else if (base=="cool") "cold" else "cool"
    for (pair in plan[[as.character(deg)]]) {
      imgs <- build_typeB_display(pair, beaker_ft=base, flask_ft=partner)
      register_display(imgs, force_id = id)
      out[[length(out)+1]] <- list(id=id, degree=deg, pair=pair, imgs=imgs)
      id <- id+1L
    }
  }
  stopifnot(id==21L)
  out
}

# Desired per-list Type-B color totals (target color counts) as (3,3,2) rotated
tb_color_quota <- function(list_id) {
  switch(as.character(list_id),
         "1" = c(o=2, g=3, p=3),  # example: (2 O, 3 G, 3 P)
         "2" = c(o=3, g=2, p=3),  # (3 O, 2 G, 3 P)
         "3" = c(o=3, g=3, p=2),  # (3 O, 3 G, 2 P)
         c(o=2, g=3, p=3)   # repeat first pattern
  )
}

# Build Type-B trials per list satisfying:
#  - two trials per degree (different colors)
#  - overall 8 trials hit the requested (3,3,2) target by choosing target object per display
make_typeB_trials <- function(list_id, designs) {
  quota <- tb_color_quota(list_id)         # desired (3,3,2) split per list (rotated across lists)
  left <- quota
  rows <- list(); k <- 1L
  
  by_deg <- split(designs, sapply(designs, function(x) as.character(x$degree)))
  for (deg in c("0","10","60","100")) {
    ds <- by_deg[[as.character(deg)]]
    stopifnot(length(ds) == 2)
    
    # ---- Display A: choose target color greedily by remaining quota
    pairA <- strsplit(ds[[1]]$pair, "-", TRUE)[[1]]       # c(firstColor, secondColor)
    # pick the one in pairA with larger remaining quota
    scoresA <- left[pairA]; scoresA[is.na(scoresA)] <- -Inf
    choiceA <- pairA[ which.max(scoresA) ]
    
    if (choiceA == pairA[1]) {
      imgs <- ds[[1]]$imgs
      tgti <- imgs["b1"]; cmpi <- imgs["b2"]; horiz <- imgs["f1"]; other <- imgs["f2"]; obj <- "beaker"
    } else {
      imgs <- ds[[1]]$imgs
      tgti <- imgs["f2"]; cmpi <- imgs["f1"]; horiz <- imgs["b1"]; other <- imgs["b2"]; obj <- "flask"
    }
    tgt <- parse_img(tgti); col <- clr_letter(tgt$color_word)
    s <- sent_num(obj, as.integer(deg), col)
    lay <- place_images(tgti, cmpi, horiz, other, target_pos="LT")
    rows[[k]] <- data.frame(
      list_id=list_id, list_name=paste0("List",list_id),
      condition="typeB", display_id=ds[[1]]$id, target_object=obj,
      adj=as.character(deg), degree=as.integer(deg),
      target_image=tgti, competitor_image=cmpi, other1_image=horiz, other2_image=other,
      LT=lay["LT"], RT=lay["RT"], LB=lay["LB"], RB=lay["RB"],
      mentioned_color=col, mentioned_color_word=tgt$color_word,
      sentence=s, instruction=s, stringsAsFactors=FALSE
    ); k <- k+1L
    left[col] <- left[col] - 1L
    
    # ---- Display B: must be a different color than A; prefer higher remaining quota among its pair
    pairB <- strsplit(ds[[2]]$pair, "-", TRUE)[[1]]
    # available options for B (prefer different from A)
    optsB <- setdiff(pairB, col)
    if (length(optsB) == 0) optsB <- pairB  # safety fallback, but construction should avoid this
    
    scoresB <- left[optsB]; scoresB[is.na(scoresB)] <- -Inf
    choiceB <- optsB[ which.max(scoresB) ]
    
    if (choiceB == pairB[1]) {
      imgs <- ds[[2]]$imgs
      tgti <- imgs["b1"]; cmpi <- imgs["b2"]; horiz <- imgs["f1"]; other <- imgs["f2"]; obj <- "beaker"
    } else {
      imgs <- ds[[2]]$imgs
      tgti <- imgs["f2"]; cmpi <- imgs["f1"]; horiz <- imgs["b1"]; other <- imgs["b2"]; obj <- "flask"
    }
    tgt <- parse_img(tgti); col2 <- clr_letter(tgt$color_word)
    if (col2 == col) stop("TypeB per-degree produced the same color twice; adjust pairs/quota.")
    s <- sent_num(obj, as.integer(deg), col2)
    lay <- place_images(tgti, cmpi, horiz, other, target_pos="LT")
    rows[[k]] <- data.frame(
      list_id=list_id, list_name=paste0("List",list_id),
      condition="typeB", display_id=ds[[2]]$id, target_object=obj,
      adj=as.character(deg), degree=as.integer(deg),
      target_image=tgti, competitor_image=cmpi, other1_image=horiz, other2_image=other,
      LT=lay["LT"], RT=lay["RT"], LB=lay["LB"], RB=lay["RB"],
      mentioned_color=col2, mentioned_color_word=tgt$color_word,
      sentence=s, instruction=s, stringsAsFactors=FALSE
    ); k <- k+1L
    left[col2] <- left[col2] - 1L
  }
  
  # Assert quotas met (each color >= 2; total 8)
  used <- quota - left
  stopifnot(all(used >= 2), sum(used) == 8)
  
  dplyr::bind_rows(rows)
}


# ==========================================================
# Build one list
# ==========================================================
build_one_list <- function(list_id, D12, tb_designs) {
  expnum <- make_expnum_trials_from_12(list_id, D12)
  # EXP+NUMBER totals are already asserted 8/8/8.
  
  tb <- make_typeB_trials(list_id, tb_designs)
  
  df <- bind_rows(expnum, tb) %>%
    arrange(factor(condition, levels=c("exp","number","typeB")), display_id, target_object)
  
  # Final corner balancing across all 32 trials (8 per corner)
  df <- assign_balanced_positions_32(df) %>%
    add_target_comp_loc() %>%
    mutate(item_id = paste0(display_id, "_", target_object),
           trial_in_list = row_number())
  
  # No color_pair in outputs
  if ("color_pair" %in% names(df)) df$color_pair <- NULL
  
  # Final per-list sanity checks
  # (1) 12 EXP/NUMBER display IDs, each used exactly twice:
  en <- df %>% filter(condition %in% c("exp","number"))
  stopifnot(length(unique(en$display_id))==12)
  stopifnot(all(table(en$display_id)==2))
  # (2) positions 8 each:
  stopifnot(all(table(df$target_loc) == c(LB=8, LT=8, RB=8, RT=8)))
  
  df
}

# ==========================================================
# Build all lists & write
# ==========================================================
build_all_lists <- function(out_dir="lists_followup_spec_v9") {
  dir.create(out_dir, recursive=TRUE, showWarnings=FALSE)
  
  D12 <- build_12_displays()       # fixed 12 displays (IDs 1..12)
  tb_designs <- build_typeB_designs() # fixed 8 displays (IDs 13..20)
  
  lists <- lapply(1:4, function(L) build_one_list(L, D12, tb_designs))
  names(lists) <- paste0("List",1:4)
  
  for (nm in names(lists)) write.csv(lists[[nm]], file.path(out_dir, paste0(nm, ".csv")), row.names=FALSE)
  combined <- dplyr::bind_rows(lists, .id="which_list")
  write.csv(combined, file.path(out_dir, "ALL_lists.csv"), row.names=FALSE)
  
  invisible(lists)
}

lists_out <- build_all_lists()
cat("Done. EXP+NUMBER use displays 1..12 exactly twice; TYPE-B uses 13..20 with (3,3,2) color splits; corners 8 each.\n")
