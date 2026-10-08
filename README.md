# Theodore on Sport

Sports questions, public data, and what the numbers will actually support.

Live at **https://minseo-theodore-kim.github.io**

---

## Publishing a piece

Write one Markdown file in `src/posts/`, named `YYYY-MM-DD-some-slug.md`.
The slug becomes the URL: `/writing/some-slug/`. Nothing else needs editing —
the hub list, dates, reading time, tags and previous/next links are generated.

```markdown
---
title: "Does a high defensive line actually cost you goals?"
date: 2026-11-09
draft: false
takeaway: "Line height explains far less than possession share does."
tags: [Regression, Football]

# optional — delete either block if a piece does not need it
tldr: >
  Two or three sentences for the box at the top.
data:
  Source: "FBref squad shooting tables"
  Period: "Premier League, 2016-17 to 2025-26"
  Sample: "200 club-seasons"
  Tools: "R (ggplot2)"
---

## The question

Write here. `##` is a section heading, `**bold**` is bold.
```

`draft: true` keeps a piece off the site while it is being written.
Set it to `false` when it is ready.

### Figures

Put the image in `src/figures/`, then in the Markdown:

```html
<figure>
  <img src="/figures/fig1-shot-volume.png" alt="Describe the chart for screen readers.">
  <figcaption><b>Fig 1</b> — Write the takeaway here, not a description of the axes.</figcaption>
</figure>
```

Export charts about 1,600px wide. A caption should say what the figure shows,
not what it is.

---

## Running it locally

Needs Node 20 or newer.

```bash
npm install     # once
npm start       # preview at http://localhost:8080, reloads as you type
npm run build   # build into _site/
```

## Publishing

Push to `main`. GitHub Actions builds the site and deploys it. The first time
only, set **Settings → Pages → Build and deployment → Source** to
**GitHub Actions**.

---

## Layout

```
src/
  index.njk           the hub
  _data/site.json     name, tagline, bio, contact — edit here, not in templates
  _includes/          page templates
  css/style.css       all styling
  posts/              one Markdown file per piece
  figures/            images
analysis/             the R project behind each piece
.github/workflows/    build and deploy
```

## Analysis

The R project that produced the figures lives in `analysis/`. Open
`analysis/theodore-on-sport.Rproj` in RStudio and click Source. Charts are
written to `analysis/figures/`; copy the ones a piece uses into `src/figures/`.
