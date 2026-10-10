# =============================================================================
# Theodore on Sport - Piece 2
# Where the 2023-24 shot spike came from
#
# Piece 1 found one season that moved: 2023-24, the only year shot volume and
# shot yield both rose. This asks what produced it. Two candidates:
#   (a) squad turnover - the three promoted clubs shot more than the three
#       relegated ones they replaced;
#   (b) the clubs that stayed shot more than they had the season before.
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

files  <- sort(list.files("data", pattern = "\\.csv$", full.names = TRUE))
squads <- do.call(rbind, lapply(files, read_season))

squads$np_goals <- squads$Gls - squads$PK
squads$np_shots <- squads$Sh  - squads$PK
squads$np_g_per_sh <- squads$np_goals / squads$np_shots

cat("Loaded", length(files), "seasons,", nrow(squads), "club-seasons\n\n")


# --- 2. Decompose the jump ----------------------------------------------------
# A league total can rise two ways: the same clubs shoot more, or the clubs
# themselves change. Promotion and relegation swap three clubs every summer,
# so the two have to be separated before anything is explained.

A <- "2022-23"; B <- "2023-24"
a <- squads[squads$season == A, ]; rownames(a) <- a$Squad
b <- squads[squads$season == B, ]; rownames(b) <- b$Squad

stayed   <- sort(intersect(a$Squad, b$Squad))
left     <- setdiff(a$Squad, b$Squad)
arrived  <- setdiff(b$Squad, a$Squad)

d_stayed   <- sum(b[stayed, "Sh"]) - sum(a[stayed, "Sh"])
d_turnover <- sum(b[arrived, "Sh"]) - sum(a[left, "Sh"])
d_total    <- sum(b$Sh) - sum(a$Sh)

cat("Decomposition of the 2022-23 -> 2023-24 change in league shots\n")
cat("-------------------------------------------------------------\n")
cat(sprintf("  league total        %+6d  (%+.2f per match)\n", d_total, d_total / 380))
cat(sprintf("  clubs that stayed   %+6d  (%5.1f%% of the change)\n",
            d_stayed, d_stayed / d_total * 100))
cat(sprintf("  promotion/relegation%+6d  (%5.1f%%)\n",
            d_turnover, d_turnover / d_total * 100))
cat(sprintf("  relegated: %s\n", paste(left, collapse = ", ")))
cat(sprintf("  promoted:  %s\n\n", paste(arrived, collapse = ", ")))

ch <- data.frame(
  club   = stayed,
  change = b[stayed, "Sh"] - a[stayed, "Sh"],
  stringsAsFactors = FALSE
)
ch <- ch[order(ch$change), ]
ch$club <- factor(ch$club, levels = ch$club)
ch$dir  <- ifelse(ch$change >= 0, "up", "down")

cat(sprintf("  of the %d clubs that stayed, %d took more shots; median %+.0f\n\n",
            nrow(ch), sum(ch$change > 0), median(ch$change)))


# --- 3. Did the spread of club shot yield change? ------------------------------
# A league average can rise because the best clubs got better or because the
# worst ones stopped being so bad. Those are different stories.

win <- c("2022-23", "2023-24", "2024-25")
sp  <- squads[squads$season %in% win, ]

cat("Club-level non-penalty goals per shot\n")
cat("-------------------------------------\n")
for (s in win) {
  v <- sp$np_g_per_sh[sp$season == s]
  lg <- sum(sp$np_goals[sp$season == s]) / sum(sp$np_shots[sp$season == s])
  cat(sprintf("  %s  league %.4f | median %.4f | min %.4f | max %.4f | sd %.4f\n",
              s, lg, median(v), min(v), max(v), sd(v)))
}
cat("\n")

meds <- aggregate(np_g_per_sh ~ season, data = sp, FUN = median)


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

# -- Figure 1: which clubs shot more
p1 <- ggplot(ch, aes(change, club, fill = dir)) +
  geom_col(width = 0.72) +
  geom_vline(xintercept = 0, colour = "#DDE3DE", linewidth = 0.6) +
  scale_fill_manual(values = c(up = ACCENT, down = GREY), guide = "none") +
  scale_x_continuous(limits = c(-80, 200), breaks = seq(-50, 200, 50)) +
  labs(title    = "Most of the clubs that stayed shot more than the year before",
       subtitle = "Change in total shots, 2022-23 to 2023-24, for the seventeen clubs present in both",
       x = "Change in shots over the season", y = NULL,
       caption  = "Data: FBref squad shooting tables. Promoted and relegated clubs are excluded because they cannot be compared with themselves.") +
  theme_tos() +
  theme(panel.grid.major.y = element_blank(),
        panel.grid.major.x = element_line(colour = GRID, linewidth = 0.4))

ggsave("figures/p2-fig1-club-shot-change.png", p1, width = 8, height = 5.6, dpi = 200)

# -- Figure 2: the spread of club shot yield, three seasons
p2 <- ggplot(sp, aes(season, np_g_per_sh)) +
  geom_jitter(width = 0.11, height = 0, shape = 21, size = 2.6, stroke = 0.9,
              colour = ACCENT, fill = "white", alpha = 0.95) +
  geom_crossbar(data = meds, aes(y = np_g_per_sh, ymin = np_g_per_sh, ymax = np_g_per_sh),
                width = 0.42, colour = INK, linewidth = 0.5) +
  scale_y_continuous(limits = c(0.055, 0.15),
                     breaks = seq(0.06, 0.14, 0.02),
                     labels = number_format(accuracy = 0.01)) +
  labs(title    = "The bottom rose and the top did not",
       subtitle = "Each dot is one club's non-penalty goals per shot. The bar marks the median",
       x = NULL, y = "Non-penalty goals per shot",
       caption  = "Data: FBref squad shooting tables. Twenty clubs per season.") +
  theme_tos() +
  theme(panel.grid.major.x = element_blank(),
        panel.grid.major.y = element_line(colour = GRID, linewidth = 0.4))

ggsave("figures/p2-fig2-yield-spread.png", p2, width = 8, height = 4.8, dpi = 200)

cat("Wrote figures/p2-fig1-club-shot-change.png\n")
cat("Wrote figures/p2-fig2-yield-spread.png\n")

write.csv(ch, "output/p2-club-shot-change.csv", row.names = FALSE)
