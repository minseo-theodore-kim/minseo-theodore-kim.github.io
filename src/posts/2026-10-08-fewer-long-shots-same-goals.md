---
title: "Fewer long shots, same goals"
date: 2026-10-08
draft: true
takeaway: "Shot volume and shot yield are both where they were ten seasons ago, which makes the usual explanation for the decline in long-range shooting harder to accept."
tags: [Regression, Football]
tldr: >
  Opta reported that long-range shooting is at a record low and explained it as
  clubs learning that closer shots convert better. If that is right, the average
  shot should have become more valuable. Across the ten seasons of public data
  that remain checkable, it has not.
data:
  Source: "FBref squad shooting tables"
  Period: "Premier League, 2016-17 to 2025-26"
  Sample: "200 club-seasons, about 96,000 shots"
  Tools: "R (ggplot2)"
  Code: "github.com/minseo-theodore-kim/minseo-theodore-kim.github.io"
---

<!--
  WRITING NOTES - delete this block before publishing.

  Every [ ... ] below is a placeholder. The numbers are already correct and
  verified; the prose is yours. Target 1,100-1,300 words.

  When the piece is ready, change `draft: true` above to `draft: false` and
  push. That is the only switch.
-->

## The claim

[ Segar's observation: 8.3 shots per match from outside the box, 31.7% of all
shots, the fewest on record since 2003-04. ]

[ Segar's explanation: clubs have recognised that closer shots are more
efficient. ]

[ The pivot sentence of the piece: an observation and an explanation are
different things. The observation is a measurement. The explanation is a story
about cause. This piece tests the explanation, not the observation. ]

## What the explanation predicts

[ If clubs are filtering out low-value attempts, two things should follow. ]

[ Prediction A: the average shot converts at a higher rate. ]

[ Prediction B: total shot volume falls. ]

[ Say explicitly that neither prediction needs shot-location data. This is the
sentence that makes the piece possible. ]

## Data and method

[ FBref squad shooting tables, ten seasons, 200 club-seasons, about 96,000
shots. ]

[ Why this window: FBref's shot counts begin at 2016-17, and Opta's advanced
statistics were withdrawn from FBref in January 2026. Ten seasons is the entire
publicly checkable record, and all ten are used. ]

[ Why penalties are excluded: they convert at roughly 76-78% against about 10%
for open play, and penalty counts rose from 81 in 2016-17 to 102 in 2020-21 as
VAR arrived. ]

[ Why league totals rather than club averages: averaging club ratios would give
a club that took 332 shots the same weight as one that took 781. ]

[ Two definitional notes: FBref does not document whether `Sh` includes penalty
attempts, so both readings were computed and they differ by at most 1.1%; and
`Gls` counts goals by a club's own players, so own goals are excluded. ]

## Shot volume has not fallen

<figure>
  <img src="/figures/fig1-shot-volume.png"
       alt="Premier League shots per match by season, 2016-17 to 2025-26, showing no decline.">
  <figcaption><b>Fig 1</b> — Shot volume in 2025-26 is where it was in 2016-17. The 2023-24 peak is the only notable movement.</figcaption>
</figure>

[ 24.26 in 2016-17, 24.99 in 2025-26. Slope +0.115 per season, R² = 0.132.
High 27.32 in 2023-24, low 23.87 in 2020-21. ]

[ Prediction B does not hold. ]

## And the average shot is worth the same

<figure>
  <img src="/figures/fig2-shot-yield.png"
       alt="Non-penalty goals per shot by season with a two-standard-error band; all ten seasons fall inside it.">
  <figcaption><b>Fig 2</b> — Ten seasons of shot yield, all inside the range chance alone would produce.</figcaption>
</figure>

[ 0.0983 in 2016-17, 0.0985 in 2025-26. Slope +0.00034 per season, R² = 0.135.
Shot accuracy tells the same story: SoT% slope +0.041 per season, R² = 0.064. ]

[ Explain the grey band in words, not just in the figure. A season is about
9,500 attempts, each succeeding about 10% of the time. The band is the range
chance alone would produce at that sample size. All ten seasons sit inside it. ]

[ Prediction A does not hold either. ]

## The window decides the answer

[ Start the series at 2017-18 instead and the same data falls from 0.1017 to
0.0985 — a decline. One additional season removes it. ]

[ This is a warning about my own result as much as anyone's: ten points is not
much power for detecting a slow trend. ]

## What this does and does not show

[ Open with: this is not a refutation of Segar's finding. ]

[ He measured where shots are taken from. I measured what the average shot
produces. Both can be true at once. ]

[ Three candidate explanations, none of which this data can separate:
  1. shot locations improved but defences improved alongside them;
  2. attempts removed from outside the box were replaced by harder attempts
     inside it;
  3. the efficiency gain was small to begin with. ]

## Limitations

[ Goals per shot measures outcome, not quality — finishing variance is mixed in.
Non-penalty xG per shot would be the right measure and is no longer publicly
available. ]

[ Ten seasons is ten points. ]

[ Whether `Sh` includes penalty attempts is undocumented. ]

[ Shot locations are invisible in this data, which means the mechanism under
discussion cannot be observed directly. ]

## Why this is hard to check now

[ The claim rests on 22 seasons of Opta records. Public access to those records
ended in January 2026. A reader cannot verify the span the claim is built on.
What follows is what can still be checked. ]

## What comes next

[ Understat publishes shot coordinates, which would allow the inside/outside
split to be rebuilt directly and the question asked again with expected goals. ]

---

**Source.** David Segar, "Analysis: Why are players shooting less from long range
this season?", Opta Analyst / Premier League, 29 March 2025.

**Data and code.** All ten CSV exports and the R script that produced these
figures are in the repository linked above.
