# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and releases are dated rather than numbered: [CalVer](https://calver.org/), as
`YYYY.MM.DD`. There is nothing here to upgrade. You copy it once and the site
becomes yours, so there is no upgrade path for a version number to describe.

Entries record what changed between releases of the starter, so anyone working
from an earlier release can see what they are missing. The first release is
described relative to a stock `statamic/statamic` install instead, since there
is no earlier version to compare it to.

## [2026.09.02]

First public release. Everything below describes the starter as it stands,
relative to a stock `statamic/statamic` install.

### Added

- Webslice build script at `.webslice/build.sh`, which writes the production environment, installs dependencies without dev packages, ensures an application key exists and builds assets with Vite.
- Webslice release script at `.webslice/release.sh`, which caches config and routes, then clears and warms the static cache.
- `.webslice/settings.toml` pointing Webslice at both scripts, so a git deploy needs no console configuration.
- `.webslice/env.production` as a production environment baseline separate from the local defaults in `.env.example`, so a deploy cannot inherit `APP_DEBUG=true`.
- Static caching rewrite rules in `public/.htaccess`, letting Apache serve pages from `public/static` without starting PHP.
- Release-time validation of `APP_URL`, which fails the release when it is empty, left at Laravel's `http://localhost` fallback, or missing its scheme. Each of those silently produces a site whose every generated URL points at localhost.
- Optional `APP_KEY`. A key set in the Console is used as given; otherwise the build generates one and keeps it in `/mnt/data/website/shared/app-key`, so every later deploy reuses it and sessions survive.
- Build-time validation of `APP_KEY`, which fails the deploy when the Console holds a key of the wrong length. A Console variable takes precedence over `.env`, so the build cannot correct that one.
- Build-time check that an application key was actually written, because `key:generate` reports failures but still exits 0.
- Contact form with a honeypot, storing submissions to disk so the Webslice provider can persist them to shared storage.
- Blog collection mounted at `/blog`, with a paginated index and two posts.
- Sitemap at `/sitemap.xml` and RSS feed at `/feed.xml`, as Antlers templates with no added dependencies.
- `site_settings` global for the site description, contact email and footer text.
- Default Control Panel super user (`admin@example.com`), with the password published in the README and a deploy step for replacing it before the site is public.
- Assets served from shared storage on Webslice. The build copies committed assets into `/mnt/data/website/shared/public/assets` and symlinks `public/assets` at it, so Control Panel uploads and their `.meta` sidecars survive versioned deploys while git stays the source of truth for tracked files.

### Changed

- Set `warm_concurrency` to 5, below the platform's default cap of 10 concurrent instances per website.
- Allowed `page` as a static caching query string, so paginated listings do not all serve the first page.
- Excluded `/contact` from static caching, because a cached page carries an expired CSRF token by the time anyone submits it.
- Excluded `/sitemap.xml` and `/feed.xml` from static caching, because the file cacher names every entry `.html` and the rewrite would serve XML as `text/html`.
- Enabled the Glide image cache, which the Webslice provider persists to shared storage between deploys.
- Removed the SQLite database provisioning and migration from `composer setup`, since Statamic is flat file and SQLite performs badly on the platform's NFS storage.

[2026.09.02]: https://github.com/webslicehq/cms-starter-statamic/releases/tag/v2026.09.02
