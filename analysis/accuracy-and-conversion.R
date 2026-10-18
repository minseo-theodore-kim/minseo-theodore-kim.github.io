# =============================================================================
# Theodore on Sport - Piece 4
# Does shot accuracy predict shot conversion?
#
# Pieces 1 to 3 used non-penalty goals per shot as the measure of what an
# average shot is worth. This piece asks whether a second public number,
# the share of shots that hit the target, carries information about that.
#
# The complication is an identity. Goals per shot is the product of two
# things:
#
#     G/Sh  =  (SoT/Sh) x (G/SoT)  =  accuracy x on-target conversion
#
# Accuracy sits on both sides of any regression of G/Sh on accuracy, so a
# positive slope appears even when every club is identical. The question is
# therefore not whether the slope is positive. It is whether the slope is
# larger than the one chance alone produces, which is what section 4 works
# out by simulation.
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

set.seed(11)


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

needed <- c("Gls", "Sh", "SoT", "PK", "PKatt")
missing <- setdiff(needed, names(squads))
if (length(missing) > 0) {
  stop("These columns are not in the CSVs: ", paste(missing, collapse = ", "),
       "\nRe-export the squad shooting table with the standard columns.")
}

# Penalties are removed throughout. The subtraction is PK, not PKatt, which
# is what pieces 1 to 3 used; keeping the definition fixed is what lets this
# piece's numbers sit beside theirs. Section 6 repeats everything with PKatt.
#
# One wrinkle that did not arise before. A penalty that is saved is still a
# shot on target, so SoT contains on-target penalties that were not scored,
# and the published tables do not say how many. That is a second reason to
# run section 6.

squads$np_goals <- squads$Gls - squads$PK
squads$np_shots <- squads$Sh  - squads$PK
squads$np_sot   <- squads$SoT - squads$PK

squads$acc     <- squads$np_sot   / squads$np_shots     # accuracy, SoT%
squads$on_tgt  <- squads$np_goals / squads$np_sot       # on-target conversion
squads$yield   <- squads$np_goals / squads$np_shots     # goals per shot

# the PKatt reading, carried only for section 6
squads$np_shots_b <- squads$Sh  - squads$PKatt
squads$np_sot_b   <- squads$SoT - squads$PKatt
squads$acc_b      <- squads$np_sot_b / squads$np_shots_b
squads$yield_b    <- squads$np_goals / squads$np_shots_b

seasons <- sort(unique(squads$season))
cat("Loaded", length(files), "seasons,", nrow(squads), "club-seasons\n")
cat("Seasons:", paste(seasons, collapse = ", "), "\n\n")


# --- 2. The identity ----------------------------------------------------------
# Stated in the header, checked here so the piece can assert it.

gap <- max(abs(squads$yield - squads$acc * squads$on_tgt))
cat(sprintf("Identity check: largest gap between G/Sh and acc x on-target = %.2e\n",
            gap))
if (gap > 1e-12) warning("The identity does not hold. Check the penalty columns.")

cat(sprintf("League-wide: accuracy %.4f | on-target conversion %.4f | yield %.4f\n\n",
            sum(squads$np_sot) / sum(squads$np_shots),
            sum(squads$np_goals) / sum(squads$np_sot),
            sum(squads$np_goals) / sum(squads$np_shots)))


# --- 3. The regression everyone would run -------------------------------------

fit <- lm(yield ~ acc, data = squads)
b_obs <- unname(coef(fit)[2])
r2_obs <- summary(fit)$r.squared

cat("Goals per shot regressed on accuracy, 200 club-seasons\n")
cat("------------------------------------------------------\n")
cat(sprintf("  slope      %+.4f\n", b_obs))
cat(sprintf("  R-squared   %.4f\n", r2_obs))
cat(sprintf("  correlation %+.4f\n\n", cor(squads$acc, squads$yield)))


# --- 4. What chance alone produces --------------------------------------------
# Under the null, every club has the same true accuracy and the same true
# on-target conversion, and only the number of shots differs. Each club's
# shots on target are drawn binomially from its own shot count, and its goals
# binomially from its own shots on target. The regression is then run on the
# simulated league exactly as in section 3.
#
# This is the null that matters, because it holds the identity fixed while
# removing every real difference between clubs.

a_true <- sum(squads$np_sot)   / sum(squads$np_shots)
c_true <- sum(squads$np_goals) / sum(squads$np_sot)
n_sh   <- squads$np_shots

REPS <- 4000
b_null  <- numeric(REPS)
r2_null <- numeric(REPS)

for (i in seq_len(REPS)) {
  sot <- rbinom(length(n_sh), n_sh, a_true)
  g   <- rbinom(length(sot), sot, c_true)
  sim <- data.frame(acc = sot / n_sh, yield = g / n_sh)
  m   <- lm(yield ~ acc, data = sim)
  b_null[i]  <- unname(coef(m)[2])
  r2_null[i] <- summary(m)$r.squared
}

b_mid <- mean(b_null)
b_ci  <- quantile(b_null, c(0.025, 0.975))
p_val <- (sum(b_null >= b_obs) + 1) / (REPS + 1)

cat("Slope expected from chance alone\n")
cat("--------------------------------\n")
cat(sprintf("  simulations            %d\n", REPS))
cat(sprintf("  true on-target rate    %.4f   (the slope the identity implies)\n", c_true))
cat(sprintf("  simulated mean slope   %+.4f\n", b_mid))
cat(sprintf("  simulated 95%% range    %+.4f to %+.4f\n", b_ci[1], b_ci[2]))
cat(sprintf("  observed slope         %+.4f\n", b_obs))
cat(sprintf("  observed minus chance  %+.4f\n", b_obs - b_mid))
cat(sprintf("  one-sided p            %.4f\n", p_val))
cat(sprintf("  simulated mean R2      %.4f   (observed %.4f)\n\n",
            mean(r2_null), r2_obs))


# --- 5. Where the real differences are ----------------------------------------
# If accuracy does carry information beyond the identity, clubs should differ
# in on-target conversion too, or they should not. Section 3 of piece 3 is
# reused here: observed spread minus the spread chance alone would produce.

sd_real <- function(x, p, n) {
  v_obs   <- mean((x - mean(x))^2)
  v_noise <- mean(p * (1 - p) / n)
  c(obs = sqrt(v_obs), noise = sqrt(v_noise), real = sqrt(max(v_obs - v_noise, 0)))
}

s_acc <- sd_real(squads$acc,    a_true, squads$np_shots)
s_on  <- sd_real(squads$on_tgt, c_true, squads$np_sot)

cat("Spread between clubs, pooled over 200 club-seasons\n")
cat("--------------------------------------------------\n")
cat(sprintf("  accuracy              observed %.4f | chance %.4f | real %.4f\n",
            s_acc["obs"], s_acc["noise"], s_acc["real"]))
cat(sprintf("  on-target conversion  observed %.4f | chance %.4f | real %.4f\n",
            s_on["obs"], s_on["noise"], s_on["real"]))
cat(sprintf("  correlation between the two: %+.4f\n\n",
            cor(squads$acc, squads$on_tgt)))


# --- 6. Does the penalty assumption change the answer? ------------------------

fit_b <- lm(yield_b ~ acc_b, data = squads)
cat("Sensitivity to how penalties are removed\n")
cat("----------------------------------------\n")
cat(sprintf("  minus PK    (main, as in pieces 1-3)  slope %+.4f   R2 %.4f\n",
            b_obs, r2_obs))
cat(sprintf("  minus PKatt (every penalty removed)   slope %+.4f   R2 %.4f\n\n",
            unname(coef(fit_b)[2]), summary(fit_b)$r.squared))


# --- 7. Season by season ------------------------------------------------------
# Pooling ten seasons lets league-wide drift masquerade as a club-level
# relationship. Running each season on its own removes that.

# Each season has to be compared with its own null. Twenty clubs produce a
# much wider range of chance slopes than two hundred do, so the pooled
# baseline from section 4 would make a single season look more decisive than
# it is. The null is therefore rebuilt inside each season, on that season's
# own shot counts and its own league rates.

SEASON_REPS <- 2000

by_season <- data.frame(season = seasons, slope = NA, r2 = NA, n = NA,
                        chance = NA, lo = NA, hi = NA, p = NA)

for (i in seq_along(seasons)) {
  d <- squads[squads$season == seasons[i], ]
  m <- lm(yield ~ acc, data = d)
  b <- unname(coef(m)[2])

  a_s <- sum(d$np_sot)   / sum(d$np_shots)
  c_s <- sum(d$np_goals) / sum(d$np_sot)
  nb  <- numeric(SEASON_REPS)
  for (k in seq_len(SEASON_REPS)) {
    sot <- rbinom(nrow(d), d$np_shots, a_s)
    g   <- rbinom(length(sot), sot, c_s)
    nb[k] <- unname(coef(lm(I(g / d$np_shots) ~ I(sot / d$np_shots)))[2])
  }

  by_season$slope[i]  <- b
  by_season$r2[i]     <- summary(m)$r.squared
  by_season$n[i]      <- nrow(d)
  by_season$chance[i] <- mean(nb)
  by_season$lo[i]     <- quantile(nb, 0.025)
  by_season$hi[i]     <- quantile(nb, 0.975)
  by_season$p[i]      <- (sum(nb >= b) + 1) / (SEASON_REPS + 1)
}

cat("Each season against its own null\n")
cat("--------------------------------\n")
print(by_season, row.names = FALSE, digits = 4)
cat(sprintf("\n  median season slope %+.4f   (pooled %+.4f)\n", median(by_season$slope), b_obs))
cat(sprintf("  seasons clearing their own 95%% chance range: %d of %d\n\n",
            sum(by_season$slope > by_season$hi), nrow(by_season)))

write.csv(by_season, "output/p4-slope-by-season.csv", row.names = FALSE)
write.csv(data.frame(simulated_slope = b_null),
          "output/p4-null-slopes.csv", row.names = FALSE)


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
      panel.grid.minor = element_blank(),
      plot.background  = element_rect(fill = "white", colour = NA),
      plot.margin      = margin(20, 22, 14, 18)
    )
}

# -- Figure 1: the 200 club-seasons, with both lines on top of them
x0 <- min(squads$acc); x1 <- max(squads$acc)
xm <- mean(squads$acc); ym <- mean(squads$yield)
lines_df <- rbind(
  data.frame(x = c(x0, x1),
             y = ym + b_obs * (c(x0, x1) - xm),
             what = "Fitted"),
  data.frame(x = c(x0, x1),
             y = ym + b_mid * (c(x0, x1) - xm),
             what = "Chance alone")
)
lines_df$what <- factor(lines_df$what, levels = c("Fitted", "Chance alone"))

p1 <- ggplot(squads, aes(acc, yield)) +
  geom_point(shape = 21, size = 2.1, stroke = 0.8,
             colour = ACCENT, fill = "white", alpha = 0.9) +
  geom_line(data = lines_df, aes(x, y, colour = what, linetype = what),
            linewidth = 0.9, inherit.aes = FALSE) +
  scale_colour_manual(values = c("Fitted" = INK, "Chance alone" = GREY),
                      name = NULL) +
  scale_linetype_manual(values = c("Fitted" = "solid", "Chance alone" = "22"),
                        name = NULL) +
  scale_x_continuous(labels = percent_format(accuracy = 1)) +
  scale_y_continuous(labels = number_format(accuracy = 0.01)) +
  labs(title    = "Accuracy and conversion rise together, as they must",
       subtitle = "Each dot is one club in one season. The dashed line is the slope the identity produces on its own",
       x = "Share of non-penalty shots on target",
       y = "Non-penalty goals per shot",
       caption = paste("Data: FBref squad shooting tables, 200 club-seasons.",
                       "The dashed line is the mean slope from 4,000 simulated leagues in which every club is identical.")) +
  theme_tos() +
  theme(legend.position = "bottom",
        legend.margin = margin(t = 4),
        panel.grid.major = element_line(colour = GRID, linewidth = 0.4))

ggsave("figures/p4-fig1-accuracy-vs-yield.png", p1,
       width = 8.4, height = 5.2, dpi = 200)

# -- Figure 2: the observed slope against the null distribution
nd <- data.frame(slope = b_null)

p2 <- ggplot(nd, aes(slope)) +
  geom_histogram(bins = 46, fill = GRID, colour = GREY, linewidth = 0.25) +
  geom_vline(xintercept = b_obs, colour = ACCENT, linewidth = 1) +
  annotate("text", x = b_obs, y = Inf, label = "observed  ", hjust = 1, vjust = 1.8,
           colour = ACCENT, fontface = "bold", size = 3.4) +
  scale_x_continuous(labels = number_format(accuracy = 0.01)) +
  labs(title    = "The observed slope against the slope chance alone would give",
       subtitle = "4,000 simulated leagues in which all twenty clubs have identical accuracy and identical finishing",
       x = "Slope of goals per shot on accuracy", y = "Simulated leagues",
       caption = "Data: FBref squad shooting tables. Each simulated club keeps its real shot count; only the outcomes are redrawn.") +
  theme_tos() +
  theme(panel.grid.major.x = element_blank(),
        panel.grid.major.y = element_line(colour = GRID, linewidth = 0.4))

ggsave("figures/p4-fig2-null-distribution.png", p2,
       width = 8.4, height = 4.8, dpi = 200)

cat("Wrote figures/p4-fig1-accuracy-vs-yield.png\n")
cat("Wrote figures/p4-fig2-null-distribution.png\n")
cat("Wrote output/p4-slope-by-season.csv\n")
cat("Wrote output/p4-null-slopes.csv\n")
