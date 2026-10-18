---
title: "The half that was already there"
date: 2026-10-18
draft: false
takeaway: "Shot accuracy does carry real information about how often a club scores, but most of the apparent relationship is arithmetic, and clubs are separated more by finishing than by aiming."
tags: [Simulation, Football]
data:
  Source: "FBref squad shooting tables"
  Period: "Premier League, 2016-17 to 2025-26"
  Sample: "200 club-seasons, about 95,000 shots"
  Tools: "R (ggplot2)"
  Code: "[Repository, data and R script](https://github.com/minseo-theodore-kim/minseo-theodore-kim.github.io/tree/main/analysis)"
---

## The question

The first three pieces rested on a single measure: non-penalty goals per shot. One other number survives in the public tables, which is the share of shots that hit the target. This piece asks whether that number is a useful stand-in for the quality of a shot.

## The trap

Goals per shot is not independent of accuracy. The two are tied by an identity: `G/Sh = (SoT/Sh) × (G/SoT)`.

Accuracy therefore sits on both sides of any regression of goals per shot on accuracy. Even if all twenty clubs were identical, that regression would return a positive slope. The question is not whether the slope is positive. It is whether the slope is larger than the one chance alone produces.

## Data and method

Ten seasons, 200 club-seasons, about 95,000 shots. Penalties are removed as in the first three pieces, by subtracting PK from goals, from shots and from shots on target. FBref does not document whether SoT includes penalty attempts, so I ran it both ways: removing every penalty attempt instead of only the scored ones moves the slope from +0.5211 to +0.5138, which does not affect anything that follows.

To find the slope that chance alone produces, I simulated 4,000 leagues in which every club has the same true accuracy and the same true finishing, and ran the same regression on each of them.

## What the obvious regression says

<figure>
  <img src="/figures/p4-fig1-accuracy-vs-yield.png"
       alt="Scatter of 200 club-seasons, share of shots on target against non-penalty goals per shot, with the fitted line and the chance line.">
  <figcaption><b>Fig 1</b> — The fitted line is steeper than the one the identity produces on its own. The gap between the two is the part that reflects real differences between clubs.</figcaption>
</figure>

The regression anyone would run first returns a slope of +0.5211, an R² of 0.4686 and a correlation of +0.6845. Taken on its own, this looks like strong evidence that accuracy predicts conversion.

## The slope chance alone produces

<figure>
  <img src="/figures/p4-fig2-null-distribution.png"
       alt="Histogram of slopes from 4,000 simulated leagues in which every club is identical, with the observed slope marked far to the right.">
  <figcaption><b>Fig 2</b> — None of the four thousand leagues in which every club was identical produced a slope as steep as the one observed.</figcaption>
</figure>

In the simulated leagues each club keeps its real shot count and only the outcomes are redrawn, so that the unequal sample sizes clubs actually have are carried into the null. Every simulated club is given the league's own rates: accuracy 0.3290 and on-target conversion 0.3079.

Those leagues return a mean slope of +0.3071, with 95 per cent of them falling between +0.2248 and +0.3898, and a mean R² of 0.2319. The observed slope of +0.5211 lies outside that range, and none of the 4,000 simulated leagues reached it.

## What is left

0.5211 − 0.3071 = +0.2139. About 59 per cent of the apparent slope is what the identity produces on its own, and roughly half of the apparent R², 0.2319 of 0.4686, is mechanical in the same way. The naive slope is about two and a half times the part that reflects real differences between clubs.

That part is real. As a rough translation of the linear fit, one percentage point of accuracy is worth about 0.0021 goals per shot, or roughly one extra goal across a season of some 475 non-penalty shots. Accuracy is not useless. It is worth considerably less than the first regression claims.

## Where the real differences are

| | Observed | Chance alone | After correction |
|---|---|---|---|
| Accuracy | 0.0273 | 0.0219 | 0.0163 |
| On-target conversion | 0.0504 | 0.0379 | 0.0332 |

Using the method of the third piece, subtracting the spread chance alone would produce, the real spread between clubs in finishing is about twice the real spread in accuracy. Measured against their own averages the gap holds: 5.0 per cent against 10.8 per cent. The two move together, at a correlation of +0.3711, so clubs that aim well tend also to finish well. But of the two, it is finishing that separates clubs.

## One season at a time

Pooling ten seasons can hide how little a single season shows. Each season was therefore compared with its own null, rebuilt on that season's twenty clubs and its own league rates, with 2,000 simulations each.

In four of the ten seasons the observed slope clears that season's 95 per cent chance range. With only twenty clubs that range runs from roughly 0.02 to 0.58, wide enough to swallow most real effects. The median season slope is +0.5315, close to the pooled +0.5211, so the seasons agree with one another. There is enough power in two hundred club-seasons to see the effect, and not enough in twenty.

The weakest season is 2025-26, at +0.3604 with p = 0.324. The 2025-26 result connects to the third piece, which found that the spread between clubs that season had narrowed to a level indistinguishable from chance. The two point the same way, though with six seasons also failing to clear their own range, no single season proves anything on its own.

## What this does not settle

This analysis does not settle four things:

1. The 200 club-seasons are not 200 independent observations. Arsenal in 2016-17 and Arsenal in 2017-18 are the same club, so the effective sample is smaller than the count suggests.
2. Shots on target is itself an outcome, not a measure of shot quality. Defenders and goalkeepers are mixed into it.
3. The shot positions remain impossible to check, so the mechanism discussed in the first piece cannot be observed directly.
4. The null assumes every club is identical, and a linear fit is used on a bounded ratio. A different null, with clubs differing in accuracy but not in finishing, would give a different baseline.

## What's next

In the next article, I am going to ask whether a club that converts well in one season does so in the next, and whether the differences that survive the correction for chance are a matter of team strength.

---

**Data and code.** All ten CSV exports and the R script that produced these
figures are in [this site's repository](https://github.com/minseo-theodore-kim/minseo-theodore-kim.github.io/tree/main/analysis).
