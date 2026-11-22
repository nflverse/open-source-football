# Open Source Football

A Quarto website (blog) for open football analytics research. See issue #101 for the modernization plan.

## Use the Quarto skills

This project enables the `quarto@posit-dev-skills` plugin (`.claude/settings.json`).
**Load its Quarto skill before creating or editing any `.qmd` file, `_quarto.yml`,
listings, themes, or render/publish setup**, and follow its guidance over general knowledge.

## Layout

- `posts/<YYYY-MM-DD-slug>/index.qmd` — new posts. `freeze: true` is set project-wide:
  authors render their post locally and commit `_freeze/posts/<slug>/`. CI never executes post code.
- `posts/<slug>/index.html` (no `.qmd`) — distill-era posts kept as pre-rendered static HTML.
  Do not edit or re-render them. Their metadata lives in `posts/archive.yml`; their shared
  JS/CSS lives in `legacy_libs/`.
- `_posts/` — original distill sources (`.Rmd`) of the archived posts (ignored by Quarto). Rendered
  output and bulky data were removed; large data/model files are assets of the `post-data` GitHub release.
- `_scripts/index-archive.ts` — post-render step adding archived posts to sitemap and search.
- `_post_template/` — template contributors copy for new posts.
- `posts/_metadata.yml` — shared execution defaults for all posts (don't use `knitr::opts_chunk$set`).

## Deployment

GitHub Pages only, via `.github/workflows/render-site.yaml` (Actions build + `deploy-pages`).
Netlify is no longer used. PR checks upload the rendered site as a `site-preview` artifact.

## Commands

- `quarto render` — build the site into `_site/` (not committed).
- `quarto render posts/<slug>/index.qmd` — execute one post and update its frozen results.
- `quarto preview` — local preview.
