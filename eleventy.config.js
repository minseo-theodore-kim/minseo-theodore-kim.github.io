module.exports = function (eleventyConfig) {
  eleventyConfig.addPassthroughCopy("src/figures");
  eleventyConfig.addPassthroughCopy("src/css");

  // 14 Sep 2026
  eleventyConfig.addFilter("readableDate", (d) =>
    new Date(d).toLocaleDateString("en-GB", {
      day: "2-digit", month: "short", year: "numeric", timeZone: "UTC",
    })
  );

  // 2026-09-14, for the <time> element
  eleventyConfig.addFilter("isoDate", (d) =>
    new Date(d).toISOString().slice(0, 10)
  );

  eleventyConfig.addFilter("readingTime", (content) => {
    const words = String(content).replace(/<[^>]*>/g, " ")
      .split(/\s+/).filter(Boolean).length;
    return Math.max(1, Math.round(words / 220));
  });

  // the collection tag "posts" is machinery, not a label for readers
  eleventyConfig.addFilter("realTags", (tags) =>
    (tags || []).filter((t) => t !== "posts")
  );

  // posts that are not drafts, newest first
  eleventyConfig.addCollection("writing", (api) =>
    api.getFilteredByTag("posts")
      .filter((p) => !p.data.draft)
      .sort((a, b) => b.date - a.date)
  );

  return {
    dir: { input: "src", includes: "_includes", output: "_site" },
    markdownTemplateEngine: "njk",
    htmlTemplateEngine: "njk",
  };
};
