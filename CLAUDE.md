# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal blog/website for Venil Noronha, built with Jekyll using the Jasper2 theme (a port of Ghost's Casper theme). The site is hosted at https://venilnoronha.io.

The repository has two branches:
- `source` — the working branch; contains source files (Markdown posts, templates, config)
- `master` — contains the built static HTML output pushed for GitHub Pages hosting

Editing happens on `source`. Building produces the static site into `_site/` (locally) or `/tmp/jasper2-pages/` (for publishing).

## Development Workflow

### Local Development (Docker)

```bash
# Build the Docker image (only needed once or after Gemfile/package.json changes)
make builder

# Serve the site locally at http://localhost:4000
make serve
```

The Docker container mounts the current directory, so file changes are reflected without rebuilding the image.

### Publishing to GitHub Pages

Publishing requires building a production site and pushing the output to `master`:

```bash
make publish   # prompts for confirmation, then builds and checks out master
```

After `make publish`, manually stage and commit the generated files on `master`, then push.

### CSS Compilation (optional)

CSS source lives in `assets/css/` and compiles to `assets/built/` via Gulp/PostCSS:

```bash
npm install
gulp       # build + watch
gulp css   # build once
```

## Content Structure

### Blog Posts (`_posts/`)

Filename format: `YYYY-MM-DD-slug.md`

Required front matter:
```yaml
---
layout: post
current: post
cover: assets/images/<slug>/banner.jpg   # optional but typical
navigation: True
title: Post Title
date: YYYY-MM-DD HH:MM:SS
tags: [Tag Name]
class: post-template
subclass: 'post tag-<tag-slug>'
author: venilnoronha
---
```

### Static Pages

- `about/index.md` — About page (uses `layout: page`)
- `conferences/index.md` — Talks/conferences listing (uses `layout: page`)
- `privacy/index.md` — Privacy policy

### Data Files

- `_data/authors.yml` — Author profiles (only one author: `venilnoronha`)
- `_data/tags.yml` — Tag metadata (descriptions, cover images)

## Key Configuration

`_config.yml` controls site-wide settings: title, social links, Google Analytics (`G-PP90X6NKJH`), Disqus comments (`venilnoronha-io`), pagination, and permalink format (`/:title`).

The `exclude:` list in `_config.yml` prevents source/build files (CSS sources, Gemfile, gulpfile, etc.) from being included in the built output.

## CI/CD

Travis CI (`.travis.yml`) auto-deploys on pushes to `master` by running `bundle exec rake site:deploy`. The `Rakefile` handles pushing generated HTML to the GitHub Pages branch.
