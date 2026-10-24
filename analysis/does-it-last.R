# =============================================================================
# Theodore on Sport - Piece 5
# Does a club's edge last into the next season?
#
# The fourth piece separated the differences between clubs that chance can
# explain from the ones it cannot, and found that what survives is larger in
# finishing than in aiming. That raises the question this piece asks.
#
# A difference that is not chance within one season is not necessarily a
# skill. If a club's edge is real but gone the following year, it was real
# and temporary. Skill is the part that comes back.
#
# So each club is paired with itself one season later, and the question is
# how much of its edge over the league it keeps.
#
# The measurement problem is the same one as in pieces 3 and 4. Both ends of
# the pair are measured with noise, which drags any year-to-year correlation
# towards zero. A correlation of 0.4 is unimpressive if the ceiling is 1.0
# and striking if the ceiling is 0.45. Section 4 works out the ceiling.
#
# Run: open theodore-on-sport.Rproj in RStudio, then Source this file.
# =============================================================================

library(ggplot2)
library(scales)

ACCENT <- "#0B6E3F"
GREY   <- "#8A948E"
INK    <- "#111614"
MUTED  <- "#5C6B62"
FAINT  <- "#9AA5A0"
GRID   <- "#EDF0EE"

set.seed(23)


# --- 1. Read ------------------------------------------------------------------

read_season <- function(path) {
  df <- read.csv(path, skip = 1, check.names = FALSE, stringsAsFactors = FALSE)
  df$season <- sub("\\.csv$", "", basename(path))
  df
}

files <- sort(list.files("data", pattern = "\\.csv$", full.names = TRUE))
if (length(files) == 0) {
  stop("No CSVs found in data/. Working directory is ", getwd(),
       "\nOpen theodore-on-sport.Rproj, or use Session > Set Working Directory.")
}
squads <- do.call(rbind, lapply(files, read_season))

squads$np_goals <- squads$Gls - squads$PK
squads$np_shots <- squads$Sh  - squads$PK
squads$np_sot   <- squads$SoT - squads$PK

squads$acc    <- squads$np_sot   / squads$np_shots
squads$on_tgt <- squads$np_goals / squads$np_sot
squads$yield  <- squads$np_goals / squads$np_shots

seasons <- sort(unique(squads$season))
cat("Loaded", length(files), "seasons,", nrow(squads), "club-seasons\n\n")

# The three measures carried through the whole script.
MEASURES <- c(acc = "Accuracy", on_tgt = "On-target conversion", yield = "Goals per shot")
# the count each one is a rate out of, for the p(1-p)/n noise term
DENOM    <- c(acc = "np_shots", on_tgt = "np_sot", yield = "np_shots")


# --- 2. Centre within season --------------------------------------------------
# A club's raw rate moves with the league. The question is not whether a club
# converted at 11 per cent twice, it is whether a club that was above the
# league one year was above it the next. Each value is therefore expressed as
# a deviation from its own season's mean, which removes league-wide drift
# before anything is correlated.

for (m in names(MEASURES)) {
  squads[[paste0(m, "_c")]] <- ave(squads[[m]], squads$season,
                                   FUN = function(v) v - mean(v))
}


# --- 3. Pair each club with itself, one season later --------------------------
# Promotion and relegation break the chain, so a club only enters a pair when
# it appears in both halves of it.

make_pairs <- function(d) {
  out <- list()
  for (i in seq_len(length(seasons) - 1)) {
    a <- d[d$season == seasons[i], ]
    b <- d[d$season == seasons[i + 1], ]
    common <- intersect(a$Squad, b$Squad)
    if (length(common) == 0) next
    rownames(a) <- a$Squad; rownames(b) <- b$Squad
    row <- data.frame(club = common, from = seasons[i], to = seasons[i + 1],
                      stringsAsFactors = FALSE)
    for (m in names(MEASURES)) {
      row[[paste0(m, "_1")]] <- a[common, paste0(m, "_c")]
      row[[paste0(m, "_2")]] <- b[common, paste0(m, "_c")]
    }
    out[[length(out) + 1]] <- row
  }
  do.call(rbind, out)
}

pairs <- make_pairs(squads)

cat(sprintf("Consecutive-season pairs: %d, from %d season-to-season steps\n",
            nrow(pairs), length(seasons) - 1))
cat(sprintf("Clubs surviving each step: %.1f of 20 on average\n\n",
            nrow(pairs) / (length(seasons) - 1)))


# --- 4. How much of the measured spread is real -------------------------------
# Reliability is the share of the variance between clubs that is not sampling
# noise. It is the same decomposition as piece 3, pooled across seasons.
#
# It is also the ceiling on any year-to-year correlation. If a club's true
# ability never changed at all, the correlation between two noisy readings of
# it would still only reach the reliability, never 1.

reliability_of <- function(m) {
  v_obs <- v_noise <- numeric(length(seasons))
  for (i in seq_along(seasons)) {
    d <- squads[squads$season == seasons[i], ]
    n <- d[[DENOM[[m]]]]
    p <- if (m == "acc")    sum(d$np_sot)   / sum(d$np_shots)
         else if (m == "on_tgt") sum(d$np_goals) / sum(d$np_sot)
         else                sum(d$np_goals) / sum(d$np_shots)
    v_obs[i]   <- mean((d[[m]] - mean(d[[m]]))^2)
    v_noise[i] <- mean(p * (1 - p) / n)
  }
  vo <- mean(v_obs); vn <- mean(v_noise)
  c(v_obs = vo, v_noise = vn, v_real = max(vo - vn, 0), rel = max(vo - vn, 0) / vo)
}

rel <- t(sapply(names(MEASURES), reliability_of))

cat("Reliability: the share of between-club variance that is not noise\n")
cat("-----------------------------------------------------------------\n")
for (m in names(MEASURES)) {
  cat(sprintf("  %-22s observed var %.6f | noise %.6f | real %.6f | reliability %.3f\n",
              MEASURES[[m]], rel[m, "v_obs"], rel[m, "v_noise"],
              rel[m, "v_real"], rel[m, "rel"]))
}
cat("\n")


# --- 4b. The same ceiling, measured on the clubs that actually form pairs -----
# The correlation in section 5 is computed on the 153 pairs, but the ceiling
# above is computed on all 200 club-seasons. Those are not the same sample.
# Relegated clubs never form a pair and they sit at one end of the league, so
# the paired sample is narrower than the full one, and a ceiling taken from
# the full one is too generous.
#
# Both versions are therefore carried into section 5. If the conclusion only
# holds under one of them, it is not a conclusion.

in_pair <- rep(FALSE, nrow(squads))
for (i in seq_len(length(seasons) - 1)) {
  a <- squads$season == seasons[i]; b <- squads$season == seasons[i + 1]
  common <- intersect(squads$Squad[a], squads$Squad[b])
  in_pair[a & squads$Squad %in% common] <- TRUE
  in_pair[b & squads$Squad %in% common] <- TRUE
}

reliability_on <- function(m, keep) {
  vo <- vn <- c()
  for (s in seasons) {
    d <- squads[squads$season == s & keep, ]
    if (nrow(d) < 3) next
    p <- if (m == "acc")    sum(d$np_sot)   / sum(d$np_shots)
         else if (m == "on_tgt") sum(d$np_goals) / sum(d$np_sot)
         else                sum(d$np_goals) / sum(d$np_shots)
    vo <- c(vo, mean((d[[m]] - mean(d[[m]]))^2))
    vn <- c(vn, mean(p * (1 - p) / d[[DENOM[[m]]]]))
  }
  v1 <- mean(vo); v2 <- mean(vn)
  max(v1 - v2, 0) / v1
}

ceil_paired <- sapply(names(MEASURES), reliability_on, keep = in_pair)

cat(sprintf("Club-seasons that enter at least one pair: %d of %d\n\n",
            sum(in_pair), nrow(squads)))


# --- 5. Observed persistence, and what it means once the ceiling is known -----

res <- data.frame(measure = unname(MEASURES), key = names(MEASURES),
                  r = NA, ceiling = NA, share = NA,
                  ceiling_p = NA, share_p = NA,
                  stringsAsFactors = FALSE)

for (i in seq_len(nrow(res))) {
  m <- res$key[i]
  r <- cor(pairs[[paste0(m, "_1")]], pairs[[paste0(m, "_2")]])
  res$r[i]         <- r
  res$ceiling[i]   <- rel[m, "rel"]
  res$share[i]     <- r / rel[m, "rel"]
  res$ceiling_p[i] <- ceil_paired[[m]]
  res$share_p[i]   <- r / ceil_paired[[m]]
}

cat("Year-to-year persistence of a club's edge over the league\n")
cat("---------------------------------------------------------\n")
cat("                          observed      ceiling, all 200      ceiling, paired only\n")
cat("  measure                        r      value     share        value      share\n")
for (i in seq_len(nrow(res))) {
  cat(sprintf("  %-22s %+8.3f  %9.3f %8.0f%%   %10.3f %8.0f%%\n",
              res$measure[i], res$r[i],
              res$ceiling[i],   100 * res$share[i],
              res$ceiling_p[i], 100 * res$share_p[i]))
}
cat("\n  The share is the correlation the underlying ability would show if it\n")
cat("  could be measured without noise. The right-hand pair is the matched\n")
cat("  comparison, since it uses the same clubs the correlation is built on.\n\n")


# --- 6. Two simulated worlds --------------------------------------------------
# The algebra in sections 4 and 5 is checked against two leagues built by hand,
# the same way piece 3 checked its correction twice.
#
#   World A: no club is better than any other, ever. Persistence should be nil.
#   World B: every club has a fixed ability it never loses, with the same
#            real spread measured in section 4. Persistence should land on
#            the ceiling.
#
# If the observed correlation sits between the two, the gap to World B is the
# part of a club's edge that does not survive the summer.

REPS <- 1500

sim_world <- function(persistent) {
  r_out <- matrix(NA, REPS, length(MEASURES),
                  dimnames = list(NULL, names(MEASURES)))
  clubs <- unique(squads$Squad)

  for (k in seq_len(REPS)) {
    sim <- squads[, c("Squad", "season", "np_shots")]

    # true rates: fixed per club in World B, league-constant in World A
    a_lg <- sum(squads$np_sot)   / sum(squads$np_shots)
    c_lg <- sum(squads$np_goals) / sum(squads$np_sot)
    if (persistent) {
      a_true <- setNames(pmin(pmax(rnorm(length(clubs), a_lg,
                          sqrt(rel["acc", "v_real"])), 0.01), 0.99), clubs)
      c_true <- setNames(pmin(pmax(rnorm(length(clubs), c_lg,
                          sqrt(rel["on_tgt", "v_real"])), 0.01), 0.99), clubs)
    } else {
      a_true <- setNames(rep(a_lg, length(clubs)), clubs)
      c_true <- setNames(rep(c_lg, length(clubs)), clubs)
    }

    sim$np_sot   <- rbinom(nrow(sim), sim$np_shots, a_true[sim$Squad])
    sim$np_goals <- rbinom(nrow(sim), sim$np_sot,   c_true[sim$Squad])
    sim$acc    <- sim$np_sot   / sim$np_shots
    sim$on_tgt <- sim$np_goals / sim$np_sot
    sim$yield  <- sim$np_goals / sim$np_shots

    for (m in names(MEASURES)) {
      sim[[paste0(m, "_c")]] <- ave(sim[[m]], sim$season,
                                    FUN = function(v) v - mean(v))
    }
    p <- make_pairs(sim)
    for (m in names(MEASURES)) {
      r_out[k, m] <- cor(p[[paste0(m, "_1")]], p[[paste0(m, "_2")]])
    }
  }
  r_out
}

wA <- sim_world(FALSE)
wB <- sim_world(TRUE)

# World B hands each club a fixed accuracy and a fixed on-target rate, so those
# two are built to a known spread and can be checked against the ceiling.
# Goals per shot is the product of the two and its spread is whatever the
# product happens to give, which is not the figure section 4 measured. World B
# therefore says nothing about that row and it is left out.
CHECKABLE <- c("acc", "on_tgt")

cat("Two simulated leagues, 1,500 each\n")
cat("---------------------------------\n")
cat("  measure                 World A (no skill)       World B (fixed skill)    observed   ceiling\n")
for (m in names(MEASURES)) {
  ca <- quantile(wA[, m], c(0.025, 0.975))
  obs <- res$r[res$key == m]; ceil <- res$ceiling[res$key == m]
  if (m %in% CHECKABLE) {
    cb <- quantile(wB[, m], c(0.025, 0.975))
    cat(sprintf("  %-22s %+.3f [%+.3f,%+.3f]   %+.3f [%+.3f,%+.3f]  %+.3f   %+.3f\n",
                MEASURES[[m]], mean(wA[, m]), ca[1], ca[2],
                mean(wB[, m]), cb[1], cb[2], obs, ceil))
  } else {
    cat(sprintf("  %-22s %+.3f [%+.3f,%+.3f]   %-24s %+.3f   %+.3f\n",
                MEASURES[[m]], mean(wA[, m]), ca[1], ca[2],
                "not calibrated, see note", obs, ceil))
  }
}
cat("\n  For the two measures World B is built on, its mean should land on the\n")
cat("  ceiling, and the observed value should sit inside its 95% range if a\n")
cat("  club's ability is in fact stable.\n\n")

for (m in CHECKABLE) {
  cb <- quantile(wB[, m], c(0.025, 0.975)); obs <- res$r[res$key == m]
  cat(sprintf("  %-22s World B mean %+.3f vs ceiling %+.3f (gap %.3f) | observed %s World B\n",
              MEASURES[[m]], mean(wB[, m]), res$ceiling[res$key == m],
              abs(mean(wB[, m]) - res$ceiling[res$key == m]),
              if (obs >= cb[1] && obs <= cb[2]) "INSIDE" else "OUTSIDE"))
  cat(sprintf("  %-22s observed %s World A\n", "",
              if (obs >= quantile(wA[, m], 0.025) && obs <= quantile(wA[, m], 0.975))
                "INSIDE" else "OUTSIDE"))
}
cat("\n")

res$wA <- colMeans(wA)[res$key]
res$wB <- colMeans(wB)[res$key]
write.csv(res, "output/p5-persistence.csv", row.names = FALSE)


# --- 7. Does the answer depend on which seasons are used? ---------------------
# The standard set in piece 1, applied again.

cat("Persistence under three windows\n")
cat("-------------------------------\n")
wins <- list("all nine steps"        = seasons,
             "dropping 2025-26"      = seasons[-length(seasons)],
             "dropping both ends"    = seasons[-c(1, length(seasons))])
for (w in names(wins)) {
  keep <- wins[[w]]
  pp <- pairs[pairs$from %in% keep & pairs$to %in% keep, ]
  cat(sprintf("  %-20s n=%3d  ", w, nrow(pp)))
  for (m in names(MEASURES)) {
    cat(sprintf("%s %+.3f   ", m, cor(pp[[paste0(m, "_1")]], pp[[paste0(m, "_2")]])))
  }
  cat("\n")
}
cat("\n")


# --- 8. Charts ----------------------------------------------------------------

theme_tos <- function() {
  theme_minimal(base_size = 12) +
    theme(
      plot.title    = element_text(face = "bold", size = 15, colour = INK,
                                   margin = margin(b = 6)),
      plot.subtitle = element_text(size = 10.5, colour = MUTED,
                                   margin = margin(b = 18)),
      plot.caption  = element_text(size = 8.5, colour = FAINT, hjust = 0,
                                   margin = margin(t = 16)),
      plot.title.position   = "plot",
      plot.caption.position = "plot",
      axis.title    = element_text(size = 9.5, colour = MUTED),
      axis.text     = element_text(size = 9.5, colour = MUTED),
      strip.text    = element_text(size = 10, colour = INK, face = "bold",
                                   hjust = 0, margin = margin(b = 6)),
      panel.grid.minor = element_blank(),
      plot.background  = element_rect(fill = "white", colour = NA),
      plot.margin      = margin(20, 22, 14, 18)
    )
}

# -- Figure 1: this season against next, for the two components
long <- rbind(
  data.frame(x = pairs$acc_1,    y = pairs$acc_2,    what = MEASURES[["acc"]]),
  data.frame(x = pairs$on_tgt_1, y = pairs$on_tgt_2, what = MEASURES[["on_tgt"]])
)
long$what <- factor(long$what, levels = c(MEASURES[["acc"]], MEASURES[["on_tgt"]]))

p1 <- ggplot(long, aes(x, y)) +
  geom_hline(yintercept = 0, colour = GRID, linewidth = 0.5) +
  geom_vline(xintercept = 0, colour = GRID, linewidth = 0.5) +
  geom_point(shape = 21, size = 2.1, stroke = 0.8,
             colour = ACCENT, fill = "white", alpha = 0.9) +
  geom_smooth(method = "lm", se = FALSE, colour = INK, linewidth = 0.8,
              formula = y ~ x) +
  facet_wrap(~ what, nrow = 1, scales = "free") +
  scale_x_continuous(labels = number_format(accuracy = 0.01)) +
  scale_y_continuous(labels = number_format(accuracy = 0.01)) +
  labs(title    = "Both halves of a club's edge come back the next season",
       subtitle = "Each dot is one club in consecutive seasons, as a deviation from that season's league average",
       x = "This season", y = "Next season",
       caption = paste("Data: FBref squad shooting tables.",
                       "Clubs enter only when they played both seasons, so promoted and relegated sides drop out.")) +
  theme_tos() +
  theme(panel.grid.major = element_line(colour = GRID, linewidth = 0.4),
        panel.spacing = unit(22, "pt"))

ggsave("figures/p5-fig1-this-season-next-season.png", p1,
       width = 8.4, height = 4.6, dpi = 200)

# -- Figure 2: observed persistence against the most that noise would allow
bars <- res
bars$measure <- factor(bars$measure, levels = rev(unname(MEASURES)))

p2 <- ggplot(bars, aes(y = measure)) +
  geom_segment(aes(x = 0, xend = ceiling, yend = measure),
               colour = GREY, linewidth = 2.6, lineend = "round", alpha = 0.35) +
  geom_segment(aes(x = 0, xend = r, yend = measure),
               colour = ACCENT, linewidth = 2.6, lineend = "round") +
  geom_text(aes(x = r, label = sprintf("%.2f    ", r)), hjust = 1,
            colour = "white", fontface = "bold", size = 3.3) +
  geom_text(aes(x = pmax(ceiling, r), label = sprintf("  ceiling %.2f", ceiling)),
            hjust = 0, colour = MUTED, size = 3) +
  scale_x_continuous(limits = c(0, max(bars$ceiling) * 1.38),
                     breaks = seq(0, 0.6, 0.2),
                     labels = number_format(accuracy = 0.1)) +
  labs(title    = "How much of the possible persistence actually shows up",
       subtitle = "Year-to-year correlation of a club's edge, against the most that measurement noise would allow",
       x = "Correlation between consecutive seasons", y = NULL,
       caption = "Data: FBref squad shooting tables. The grey bar is the correlation a perfectly stable ability would still be held to by sampling noise.") +
  theme_tos() +
  theme(panel.grid.major.y = element_blank(),
        panel.grid.major.x = element_line(colour = GRID, linewidth = 0.4))

ggsave("figures/p5-fig2-persistence-vs-ceiling.png", p2,
       width = 8.4, height = 4.2, dpi = 200)

cat("Wrote figures/p5-fig1-this-season-next-season.png\n")
cat("Wrote figures/p5-fig2-persistence-vs-ceiling.png\n")
cat("Wrote output/p5-persistence.csv\n")
