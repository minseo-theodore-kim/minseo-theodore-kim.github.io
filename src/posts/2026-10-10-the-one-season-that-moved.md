---
title: "The one season that moved"
date: 2026-10-10
draft: false
takeaway: "The extra shots in 2023-24 came from the clubs already in the league, and the higher scoring rate came from the clubs that had been converting worst."
tags: [Descriptive, Football]
data:
  Source: "FBref squad shooting tables"
  Period: "Premier League, 2022-23 to 2024-25"
  Sample: "60 club-seasons, about 29,700 shots"
  Tools: "R (ggplot2)"
  Code: "[Repository, data and R script](https://github.com/minseo-theodore-kim/minseo-theodore-kim.github.io/tree/main/analysis)"
---

## The leftover question

In the previous article, neither shot volume nor shot yield moved in the Premier League. The only exception was 2023-24, with 27.32 shots per game, 0.1070 npG/Sh, both being the highest among the ten seasons. The article did not examine the outlier, which this article does.

## Two ways a league total can rise

There are two ways a league total increases:

a) Existing teams shoot more.
b) Team composition changes, with three teams relegated and three teams promoted every season.

Before explanation, the two should be distinguished.

## It was the clubs that stayed

I compared 2022-23 with 2023-24. Compared to 2022-23, 2023-24 has +872 shots (+2.29 per game), where the remaining seventeen teams recorded +939 (107.7%) and the three promoted clubs took 67 fewer shots than the three relegated clubs they replaced (-7.7%). The relegated teams were Leeds United, Leicester City, Southampton, and the promoted teams were Burnley, Luton Town, Sheffield United. The share exceeds 100% because turnover pulled in the opposite direction: the clubs that stayed added 939 shots, and the change of clubs subtracted 67 of them.

The increase is broad rather than concentrated, as thirteen of the seventeen clubs that stayed took more shots, with a median of +70. Bournemouth recorded +181, and Liverpool recorded +180, which are two notably big increases.

<figure>
  <img src="/figures/p2-fig1-club-shot-change.png"
       alt="Change in total shots for the seventeen clubs present in both 2022-23 and 2023-24; thirteen of them increased.">
  <figcaption><b>Fig 1</b> — The extra shots came from clubs already in the league, not from the ones that replaced the relegated three.</figcaption>
</figure>

## But the scoring rate came from the bottom

| Season | League | Median | Lowest | Highest | SD |
|---|---|---|---|---|---|
| 2022-23 | 0.1023 | 0.1033 | 0.0616 | 0.1429 | 0.0225 |
| 2023-24 | 0.1070 | 0.1058 | 0.0732 | 0.1404 | 0.0188 |
| 2024-25 | 0.1045 | 0.1036 | 0.0731 | 0.1399 | 0.0180 |

The lowest value rose from 0.0616 to 0.0732, while the highest fell from 0.1429 to 0.1404. The standard deviation also decreased. The increase of the average is attributable to the improvement of the clubs with the lowest conversion rates rather than the improvement of the clubs already converting best.

<figure>
  <img src="/figures/p2-fig2-yield-spread.png"
       alt="Club-level non-penalty goals per shot for 2022-23, 2023-24 and 2024-25; the lowest values rise while the highest do not.">
  <figcaption><b>Fig 2</b> — The lowest conversion rates rose. The highest did not.</figcaption>
</figure>

## What this does not settle

There are four things that this analysis does not settle:

1. The two-season comparison does not tell causality. It only shows what changed.
2. Most of the values returned in 2024-25 (25.70 shots, 0.1045). It may be only a temporary phenomenon.
3. I cannot find why the floor rose.
4. There are no accessible shot position data, so I could not check whether these were better shots.

## What's next

In the next article, I am going to take the same question to the clubs rather than the league.

---

**Data and code.** All ten CSV exports and the R script that produced these figures are in [this site's repository](https://github.com/minseo-theodore-kim/minseo-theodore-kim.github.io/tree/main/analysis).
