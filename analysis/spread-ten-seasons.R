# =============================================================================
# Theodore on Sport - Piece 3
# Has the gap between clubs narrowed?
#
# Pieces 1 and 2 looked at league averages and found almost nothing moving.
# This asks a different question: not where the average sat, but how widely
# clubs were spread around it.
#
# The complication is that some of the measured spread is not real. A club
# takes about 475 non-penalty shots a season and converts about one in ten,
# so even twenty identical clubs would post different rates by chance alone.
# That sampling noise has to be removed before any spread can be called real.
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
squads$np_g_per_sh <- squads$np_goals / squads$np_shots

seasons <- sort(unique(squads$season))
cat("Loaded", length(files), "seasons,", nrow(squads), "club-seasons\n\n")


# --- 2. Observed spread, sampling noise, and what is left ----------------------
# Observed variance between clubs = real variance + sampling variance.
# For a club with n shots converting at rate p, the sampling variance of its
# rate is p(1-p)/n. Averaging that across the twenty clubs gives the variance
# that chance alone would produce, which is subtracted from what we measured.

spread <- data.frame(season = seasons, obs = NA, noise = NA, real = NA)

for (i in seq_along(seasons)) {
  d <- squads[squads$season == seasons[i], ]
  p <- sum(d$np_goals) / sum(d$np_shots)          # league rate that season
  v_obs   <- mean((d$np_g_per_sh - mean(d$np_g_per_sh))^2)
  v_noise <- mean(p * (1 - p) / d$np_shots)
  spread$obs[i]   <- sqrt(v_obs)
  spread$noise[i] <- sqrt(v_noise)
  spread$real[i]  <- sqrt(max(v_obs - v_noise, 0))
}

print(spread, row.names = FALSE, digits = 4)
cat(sprintf("\nMean shots per club-season: %.0f\n\n", mean(squads$np_shots)))


# --- 3. Trends, and how much they depend on the window -------------------------
# Piece 1 found that moving the start of the window by one season reversed the
# apparent direction. The same test is applied here to this piece's own result.

slope_of <- function(v) {
  t <- seq_along(v) - 1
  m <- lm(v ~ t)
  c(slope = unname(coef(m)[2]), r2 = summary(m)$r.squared, n = length(v))
}

windows <- list(
  "all ten seasons"            = seq_along(seasons),
  "dropping 2025-26"           = seq_len(length(seasons) - 1),
  "dropping both end seasons"  = 2:(length(seasons) - 1)
)

cat("Trend in spread, under three windows\n")
cat("------------------------------------\n")
for (w in names(windows)) {
  idx <- windows[[w]]
  o <- slope_of(spread$obs[idx]); r <- slope_of(spread$real[idx])
  cat(sprintf("  %-26s n=%2d   as measured %+.5f (R2 %.3f)   after correction %+.5f (R2 %.3f)\n",
              w, o["n"], o["slope"], o["r2"], r["slope"], r["r2"]))
}
cat("\n")

write.csv(spread, "output/p3-spread-by-season.csv", row.names = FALSE)


# --- 4. Charts ----------------------------------------------------------------

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
      panel.grid.minor = element_blank(),
      plot.background  = element_rect(fill = "white", colour = NA),
      plot.margin      = margin(20, 22, 14, 18)
    )
}

# -- Figure 1: every club, every season. Piece 2's picture, extended.
meds <- aggregate(np_g_per_sh ~ season, data = squads, FUN = median)

p1 <- ggplot(squads, aes(season, np_g_per_sh)) +
  geom_jitter(width = 0.13, height = 0, shape = 21, size = 2.2, stroke = 0.8,
              colour = ACCENT, fill = "white", alpha = 0.95) +
  geom_crossbar(data = meds,
                aes(y = np_g_per_sh, ymin = np_g_per_sh, ymax = np_g_per_sh),
                width = 0.46, colour = INK, linewidth = 0.4) +
  scale_y_continuous(limits = c(0.045, 0.155),
                     breaks = seq(0.06, 0.14, 0.02),
                     labels = number_format(accuracy = 0.01)) +
  labs(title    = "Clubs have drifted towards each other",
       subtitle = "Each dot is one club's non-penalty goals per shot. The bar marks the season median",
       x = NULL, y = "Non-penalty goals per shot",
       caption  = "Data: FBref squad shooting tables. Twenty clubs in each of ten seasons.") +
  theme_tos() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        panel.grid.major.x = element_blank(),
        panel.grid.major.y = element_line(colour = GRID, linewidth = 0.4))

ggsave("figures/p3-fig1-club-spread-ten-seasons.png", p1,
       width = 8.4, height = 5, dpi = 200)

# -- Figure 2: how much of that spread is real
long <- rbind(
  data.frame(season = spread$season, sd = spread$obs,  what = "As measured"),
  data.frame(season = spread$season, sd = spread$real, what = "After removing sampling noise")
)
long$what <- factor(long$what, levels = c("As measured", "After removing sampling noise"))
lab_at <- c("As measured" = "2024-25",
            "After removing sampling noise" = "2019-20")
ends <- long[mapply(function(w, se) se == lab_at[[as.character(w)]],
                    long$what, long$season), ]
ends$vj <- ifelse(ends$what == "As measured", -1.5, 2.4)

p2 <- ggplot(long, aes(season, sd, colour = what, group = what)) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 2.4, shape = 21, fill = "white", stroke = 1) +
  geom_text(data = ends, aes(label = what, vjust = vj),
            size = 3.2, fontface = "bold", show.legend = FALSE) +
  scale_colour_manual(values = c("As measured" = GREY,
                                 "After removing sampling noise" = ACCENT),
                      name = NULL) +
  scale_y_continuous(limits = c(-0.0008, 0.028), breaks = seq(0, 0.025, 0.005),
                     labels = number_format(accuracy = 0.001)) +
  labs(title    = "Most of the remaining gap between clubs is chance",
       subtitle = "Standard deviation of club non-penalty goals per shot, before and after removing sampling noise",
       x = NULL, y = "Standard deviation across clubs",
       caption  = paste("Data: FBref squad shooting tables. A club takes about 475 non-penalty shots a season,",
                        "so chance alone produces a standard deviation of roughly 0.014.")) +
  theme_tos() +
  theme(legend.position = "none",
        axis.text.x = element_text(angle = 45, hjust = 1),
        panel.grid.major.x = element_blank(),
        panel.grid.major.y = element_line(colour = GRID, linewidth = 0.4))

ggsave("figures/p3-fig2-spread-corrected.png", p2, width = 8.4, height = 5, dpi = 200)

cat("Wrote figures/p3-fig1-club-spread-ten-seasons.png\n")
cat("Wrote figures/p3-fig2-spread-corrected.png\n")
cat("Wrote output/p3-spread-by-season.csv\n")

# --- 5. Two independent checks on the correction -------------------------------
# The correction above rests on one assumption: that the spread chance alone
# produces has variance p(1-p)/n per club. Rather than trust the algebra, it is
# checked twice - once by simulation, once against a standard test.

cat("Check A - simulation: what spread would twenty identical clubs produce?\n")
set.seed(7)
for (s in seasons) {
  d <- squads[squads$season == s, ]
  p <- sum(d$np_goals) / sum(d$np_shots)
  sims <- replicate(3000, sd(rbinom(nrow(d), d$np_shots, p) / d$np_shots) *
                      sqrt((nrow(d) - 1) / nrow(d)))
  cat(sprintf("  %s  formula %.4f | simulated %.4f | observed %.4f\n",
              s, spread$noise[spread$season == s], mean(sims),
              spread$obs[spread$season == s]))
}

cat("\nCheck B - chi-square test of homogeneity across the twenty clubs\n")
cat(sprintf("  critical value at 5%% with 19 degrees of freedom: %.1f\n",
            qchisq(0.95, 19)))
chi <- data.frame(season = seasons, x2 = NA, p = NA)
for (i in seq_along(seasons)) {
  d <- squads[squads$season == seasons[i], ]
  m <- cbind(d$np_goals, d$np_shots - d$np_goals)
  tst <- suppressWarnings(chisq.test(m))
  chi$x2[i] <- unname(tst$statistic); chi$p[i] <- tst$p.value
  cat(sprintf("  %s  X2 = %5.1f  X2/df = %.2f  p = %.4f\n",
              seasons[i], chi$x2[i], chi$x2[i] / 19, chi$p[i]))
}
write.csv(chi, "output/p3-chisq-by-season.csv", row.names = FALSE)