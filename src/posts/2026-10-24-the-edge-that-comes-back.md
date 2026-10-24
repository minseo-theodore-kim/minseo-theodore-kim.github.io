---
title: "The edge that comes back"
date: 2026-10-24
draft: false
takeaway: "The differences between clubs that survive the correction for chance come back the next season, and behave like skill rather than luck."
tags: [Reliability, Football]
data:
  Source: "FBref squad shooting tables"
  Period: "Premier League, 2016-17 to 2025-26"
  Sample: "153 consecutive-season pairs, from 200 club-seasons"
  Tools: "R (ggplot2)"
  Code: "[Repository, data and R script](https://github.com/minseo-theodore-kim/minseo-theodore-kim.github.io/tree/main/analysis)"
---

## The question the first four pieces left

The first piece found that the league average had not moved. The second found that only one season moved, and traced where it came from. The third found that the differences between clubs had narrowed to a level chance could explain. The fourth found that most of the apparent link between accuracy and conversion was produced by the arithmetic tying the two together.

All four looked only inside a single season.

## A real difference is not yet a skill

A difference that chance cannot explain within one season is not yet a skill. It may be genuine and temporary. Skill is the part that comes back.

So each club is paired with itself one season later, and the question is how much of its edge over the league it keeps.

## Data and method

Only clubs that played both halves of a pair enter it. Promotion and relegation break the chain, so an average of 17.0 of the twenty clubs survive each step, which gives 153 pairs across nine steps.

Each value is expressed as a deviation from its own season's average before anything is correlated. The question is not whether a club converted at the same rate twice, but whether a club that was above the league one year was above it the next, and that requires removing league-wide drift first.

Because the variances here are measured inside each season rather than pooled across all ten, they come out slightly smaller than the fourth piece's figures. The real spread in accuracy was 0.0163 there and is 0.0156 here. It is the same quantity grouped two different ways, not a contradiction.

## What a club keeps

<figure>
  <img src="/figures/p5-fig1-this-season-next-season.png"
       alt="Two panels showing each club's accuracy and on-target conversion in one season against the next, as deviations from the league average, both sloping upward.">
  <figcaption><b>Fig 1</b> — Both panels slope upward. A club that stood above the league one season tended to stand above it the next.</figcaption>
</figure>

The observed year-to-year correlations are +0.336 for accuracy, +0.345 for on-target conversion and +0.424 for goals per shot.

These cannot be judged on their own. Whether 0.34 is large depends on what it is compared with.

## The ceiling

Both ends of a pair are measurements carrying noise, so even if a club's true ability never changed, the correlation between the two readings would not reach 1. The most it could reach is the reliability: the share of the measured variance between clubs that is not noise. It is the same decomposition the third and fourth pieces used.

| Measure | Real spread | Ceiling | Correlation | Share of ceiling |
|---|---|---|---|---|
| Accuracy | 0.0156 | 0.335 | +0.336 | 100% |
| On-target conversion | 0.0321 | 0.417 | +0.345 | 83% |
| Goals per shot | 0.0150 | 0.533 | +0.424 | 80% |

Accuracy sits at its ceiling. The other two reach more than 80 per cent of theirs. A correlation of 0.34 looks weak on its own, but for accuracy it is the most that noise allows.

Measuring the ceiling on the same clubs the correlation is built on, the 181 club-seasons that enter a pair rather than all 200, lowers it to 0.326, 0.376 and 0.486, and raises the three shares to 103, 92 and 87 per cent. The answer does not depend on which of the two samples is used.

One caution. A share of 100 per cent is not perfect persistence. It means the correlation and the ceiling cannot be told apart within the precision of the estimates.

## Two leagues built by hand

As in the third piece, I did not take the algebra on trust and checked it by a second route.

Two worlds were built. In World A no club is better than any other. In World B every club holds a fixed ability it never loses, spread as widely as the real differences measured above. Each world was run 1,500 times.

| Measure | World A, no skill | World B, fixed skill | Observed |
|---|---|---|---|
| Accuracy | −0.006 (−0.169 to +0.164) | +0.330 (+0.121 to +0.537) | +0.336 |
| On-target conversion | +0.005 (−0.156 to +0.161) | +0.412 (+0.192 to +0.612) | +0.345 |

<figure>
  <img src="/figures/p5-fig2-persistence-vs-ceiling.png"
       alt="Bar chart comparing the observed year-to-year correlation of each measure against the ceiling that sampling noise allows.">
  <figcaption><b>Fig 2</b> — How close each measure came to the most persistence that measurement noise would allow.</figcaption>
</figure>

Two things follow. World B's average lands on the ceiling, within 0.005, which means the algebra is right. And for both measures the observed value sits outside World A's range and inside World B's.

So this is not a league in which clubs do not differ, and it cannot be told apart from one in which their abilities never change at all.

## How much rests on which seasons

I apply the standard I set in the first piece to my own result.

| Window | Pairs | Accuracy | On-target conversion | Goals per shot |
|---|---|---|---|---|
| All nine steps | 153 | +0.336 | +0.345 | +0.424 |
| Dropping 2025-26 | 136 | +0.362 | +0.358 | +0.444 |
| Dropping both end seasons | 119 | +0.404 | +0.393 | +0.472 |

The direction holds in every window, and the correlations grow as the window narrows. Unlike the first piece, no window reverses the result.

## What this does not settle

This analysis does not settle four things:

1. There is not enough statistical power to separate an ability that is entirely fixed from one that decays. World B's 95 per cent range runs from 0.12 to 0.54, and 153 pairs cannot tell those two cases apart.
2. I looked only one season ahead. Whether an edge survives two seasons or three is a different question.
3. Three clubs are relegated every year and they cluster at the weaker end of the league, so the surviving seventeen are not a random sample. Measuring the ceiling on the same clubs addresses the comparison but not the bias itself.
4. Persistence does not explain itself. This data cannot separate what is being kept, whether it is the manager, the squad or the tactics.

## What's next

This closes a series of five. The first four asked what is real. This one asked what lasts.

The limitation running through all of them is that I never saw where the shots were taken from. Understat publishes shot coordinates, which would make it possible to ask the first piece's question directly.

---

**Data and code.** All ten CSV exports and the R script that produced these
figures are in [this site's repository](https://github.com/minseo-theodore-kim/minseo-theodore-kim.github.io/tree/main/analysis).
