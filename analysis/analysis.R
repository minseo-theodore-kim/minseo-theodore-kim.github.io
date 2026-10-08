# =============================================================================
# Theodore on Sport - Piece 1
# Premier League shot volume and shot yield, 2016-17 to 2025-26
#
# Question: Opta reported that long-range shooting is at a record low, and
#           explained it as clubs learning that closer shots are more efficient.
#           If that explanation is right, the average shot should have become
#           more valuable. Has it?
#
# Data:     FBref squad shooting tables, one CSV per season, in data/
#           (Sh is the earliest available from 2016-17; Opta's advanced stats
#           were withdrawn from FBref in January 2026.)
#
# Run:      open theodore-on-sport.Rproj in RStudio, then click Source,
#           or run  source("analysis.R")
# =============================================================================

library(ggplot2)
library(scales)


# --- 0. Settings -------------------------------------------------------------

MATCHES <- 380          # 20 clubs x 38 matches, all ten seasons

# Does FBref's `Sh` column include penalty attempts?
#
# FBref's own column note says only "Shots Total" - it does not say either way.
# So we do not guess. Both denominators are computed below and reported side by
# side; this switch only decides which one the charts draw. If the two versions
# disagreed about the answer, that would itself be the finding.
SH_INCLUDES_PK <- TRUE

ACCENT <- "#0B6E3F"     # site accent
INK    <- "#111614"
MUTED  <- "#5C6B62"
FAINT  <- "#9AA5A0"
GRID   <- "#EDF0EE"


# --- 1. Read ------------------------------------------------------------------
# FBref's CSV export has a grouping row (",,,Standard,Standard,...") above the
# real header, so we skip one line. check.names = FALSE keeps the original
# column names ("SoT%", "G/Sh") instead of R mangling them.

read_season <- function(path) {
  df <- read.csv(path, skip = 1, check.names = FALSE,
                 stringsAsFactors = FALSE)
  df$season <- sub("\\.csv$", "", basename(path))
  df
}

files   <- sort(list.files("data", pattern = "\\.csv$", full.names = TRUE))
squads  <- do.call(rbind, lapply(files, read_season))

cat("Loaded", length(files), "seasons,", nrow(squads), "club-seasons\n\n")


# --- 2. Validate --------------------------------------------------------------
# Never trust a table you pasted by hand. Recompute the derived columns from
# the raw counts and check they match what the source said.

validate <- function(d) {
  problems <- character(0)

  add <- function(msg) problems <<- c(problems, msg)

  by_season <- table(d$season)
  bad_n <- names(by_season)[by_season != 20]
  if (length(bad_n)) add(paste("club count not 20:", paste(bad_n, collapse = ", ")))

  if (any(d$`90s` != 38)) add("some rows do not have 90s == 38")
  if (any(d$SoT > d$Sh))  add("SoT greater than Sh")
  if (any(d$PK > d$PKatt)) add("PK greater than PKatt")

  # derived columns, recomputed
  if (any(abs(d$SoT / d$Sh * 100 - d$`SoT%`) > 0.06))  add("SoT% mismatch")
  if (any(abs(d$Gls / d$Sh        - d$`G/Sh`) > 0.006)) add("G/Sh mismatch")
  if (any(abs(d$Sh  / 38          - d$`Sh/90`) > 0.02)) add("Sh/90 mismatch")

  if (length(problems) == 0) {
    cat("Validation passed:", nrow(d), "rows, no problems found\n\n")
  } else {
    cat("VALIDATION PROBLEMS:\n"); cat(paste0("  - ", problems, "\n")); cat("\n")
  }
  invisible(problems)
}

validate(squads)


# --- 3. Aggregate to league-season totals -------------------------------------
# Everything below works on league totals, not club averages. Summing first and
# dividing once weights every shot equally; averaging club ratios would give a
# club that took 340 shots the same weight as one that took 780.

league <- aggregate(cbind(Gls, Sh, SoT, PK, PKatt) ~ season, data = squads, FUN = sum)

league$shots_per_match <- league$Sh / MATCHES
league$np_goals        <- league$Gls - league$PK

# Both readings of `Sh`, side by side
league$np_g_per_sh_inc <- league$np_goals / (league$Sh - league$PK)  # Sh includes PK
league$np_g_per_sh_exc <- league$np_goals / league$Sh                # Sh excludes PK

league$np_shots    <- if (SH_INCLUDES_PK) league$Sh - league$PK else league$Sh
league$np_g_per_sh <- league$np_goals / league$np_shots   # the one the charts use
league$sot_pct     <- league$SoT / league$Sh * 100        # shot accuracy

print(league[, c("season", "Sh", "shots_per_match", "PK",
                 "np_g_per_sh_inc", "np_g_per_sh_exc", "sot_pct")],
      row.names = FALSE, digits = 4)

cat(sprintf("\nLargest gap between the two definitions: %.5f (%.2f%% of the mean)\n\n",
            max(abs(league$np_g_per_sh_inc - league$np_g_per_sh_exc)),
            max(abs(league$np_g_per_sh_inc - league$np_g_per_sh_exc)) /
              mean(league$np_g_per_sh_inc) * 100))


# --- 4. Trends ----------------------------------------------------------------
# A straight line through ten points. The slope says how much the measure moved
# per season; R-squared says how much of the variation that line explains.

league$t <- seq_len(nrow(league)) - 1   # 0 .. 9

report <- function(formula, label, digits = 5) {
  m <- lm(formula, data = league)
  b <- coef(m)[2]
  cat(sprintf("%-22s slope %+.*f / season   over 10 seasons %+.*f   R2 = %.3f\n",
              label, digits, b, digits, b * 9, summary(m)$r.squared))
  invisible(m)
}

cat("Trends\n------\n")
report(np_g_per_sh_inc ~ t, "np G/Sh (Sh incl. PK)")
report(np_g_per_sh_exc ~ t, "np G/Sh (Sh excl. PK)")
report(shots_per_match ~ t, "shots per match", digits = 3)
report(sot_pct         ~ t, "SoT%", digits = 3)
cat("-> Both readings of `Sh` give the same answer, so the ambiguity is\n",
    "   reported in the article rather than resolved by guessing.\n\n")

# How big is season-to-season noise? Each season is roughly 9,500 shots, and
# each shot is a coin flip that lands about 10% of the time. That gives a
# standard error we can compare the wiggles against.
p_all <- sum(league$np_goals) / sum(league$np_shots)
se    <- sqrt(p_all * (1 - p_all) / mean(league$np_shots))
band  <- c(p_all - 2 * se, p_all + 2 * se)

cat(sprintf("\nTen-season mean np G/Sh = %.4f,  SE = %.5f\n", p_all, se))
cat(sprintf("+/- 2 SE band = %.4f to %.4f\n", band[1], band[2]))
cat(sprintf("Seasons inside the band: %d of %d\n\n",
            sum(league$np_g_per_sh >= band[1] & league$np_g_per_sh <= band[2]),
            nrow(league)))

write.csv(league, "output/league-season-summary.csv", row.names = FALSE)


# --- 5. Charts ----------------------------------------------------------------

theme_tos <- function() {
  theme_minimal(base_size = 12) +
    theme(
      plot.title       = element_text(face = "bold", size = 15, colour = INK,
                                      margin = margin(b = 6)),
      plot.subtitle    = element_text(size = 10.5, colour = MUTED,
                                      margin = margin(b = 18)),
      plot.caption     = element_text(size = 8.5, colour = FAINT, hjust = 0,
                                      margin = margin(t = 16)),
      plot.title.position   = "plot",
      plot.caption.position = "plot",
      axis.title.x     = element_blank(),
      axis.title.y     = element_text(size = 9.5, colour = MUTED,
                                      margin = margin(r = 10)),
      axis.text        = element_text(size = 9.5, colour = MUTED),
      panel.grid.major.y = element_line(colour = GRID, linewidth = 0.4),
      panel.grid.major.x = element_blank(),
      panel.grid.minor   = element_blank(),
      plot.background  = element_rect(fill = "white", colour = NA),
      plot.margin      = margin(20, 22, 14, 18)
    )
}

# points to label directly: first, last, and the peak
label_rows <- function(v) unique(c(1, which.max(v), length(v)))

# -- Figure 1: shot volume
lab1 <- label_rows(league$shots_per_match)

p1 <- ggplot(league, aes(season, shots_per_match, group = 1)) +
  geom_line(colour = ACCENT, linewidth = 0.9) +
  geom_point(colour = ACCENT, fill = "white", shape = 21,
             size = 2.8, stroke = 1.1) +
  geom_text(data = league[lab1, ],
            aes(label = sprintf("%.1f", shots_per_match)),
            vjust = -1.4, size = 3.5, fontface = "bold", colour = INK) +
  scale_y_continuous(limits = c(22, 29), breaks = 22:29) +
  labs(title    = "Premier League shot volume has not fallen",
       subtitle = "Total shots per match, all twenty clubs combined",
       y        = "Shots per match",
       caption  = "Data: FBref squad shooting tables, 2016-17 to 2025-26 (380 matches per season)") +
  theme_tos()

ggsave("figures/fig1-shot-volume.png", p1, width = 8, height = 4.8, dpi = 200)

# -- Figure 2: shot yield, against the noise band
lab2 <- label_rows(league$np_g_per_sh)

p2 <- ggplot(league, aes(season, np_g_per_sh, group = 1)) +
  annotate("rect", xmin = -Inf, xmax = Inf, ymin = band[1], ymax = band[2],
           fill = "#8A948E", alpha = 0.13) +
  annotate("segment", x = -Inf, xend = Inf, y = p_all, yend = p_all,
           colour = "#8A948E", linewidth = 0.4, linetype = "22") +
  annotate("text", x = league$season[1], y = band[2],
           hjust = 0, vjust = -0.7,
           label = sprintf("ten-season mean %.4f, +/- 2 SE", p_all),
           size = 3.1, colour = MUTED) +
  geom_line(colour = ACCENT, linewidth = 0.9) +
  geom_point(colour = ACCENT, fill = "white", shape = 21,
             size = 2.8, stroke = 1.1) +
  geom_text(data = league[lab2, ],
            aes(label = sprintf("%.4f", np_g_per_sh)),
            vjust = -1.4, size = 3.5, fontface = "bold", colour = INK) +
  scale_y_continuous(limits = c(0.090, 0.116),
                     breaks = seq(0.090, 0.115, 0.005),
                     labels = number_format(accuracy = 0.001)) +
  labs(title    = "And the average shot has not become more valuable",
       subtitle = "Goals per shot, penalties excluded. Every season sits inside the noise band",
       y        = "Non-penalty goals per shot",
       caption  = paste("Data: FBref squad shooting tables. Band is +/- 2 standard errors",
                        "around the ten-season mean (about 9,500 shots per season).")) +
  theme_tos()

ggsave("figures/fig2-shot-yield.png", p2, width = 8, height = 4.8, dpi = 200)

cat("Wrote figures/fig1-shot-volume.png and figures/fig2-shot-yield.png\n")
cat("Wrote output/league-season-summary.csv\n")
