# How this starter works on Webslice

Reference for the Webslice specific parts of this site: what a deploy does,
how static caching is wired up, and which directories survive a deploy.
[`README.md`](../README.md) covers getting the site running and deployed.

- [The Webslice specific files](#the-webslice-specific-files)
- [How a deploy runs](#how-a-deploy-runs)
- [Deploy strategies](#deploy-strategies)
- [Static caching](#static-caching)
- [What survives a deploy](#what-survives-a-deploy)
- [Databases](#databases)
- [Editing content in production](#editing-content-in-production)

## The Webslice specific files

Everything else in the repository is an ordinary Statamic site, covered in
[`editing-the-site.md`](editing-the-site.md).

| Path | What it does |
| --- | --- |
| `.webslice/settings.toml` | Points Webslice at the build and release scripts, so a git deploy needs no console configuration. |
| `.webslice/build.sh` | Runs during the deploy, before the release goes live: environment, dependencies, shared storage, asset build. |
| `.webslice/release.sh` | Runs after the release is live: framework caches, then clears and warms the static cache. |
| `.webslice/env.production` | The production environment baseline, copied to `.env` by the build. Not secrets - those go in the Console. |
| `public/.htaccess` | The rewrite rules that let Apache serve statically cached pages without starting PHP. |
| `config/statamic/static_caching.php` | Which pages are cached, which are excluded, and how many are warmed at once. |

## How a deploy runs

1. You push to the watched branch, and the webhook tells Webslice.
2. Webslice checks out the repository.
3. `.webslice/build.sh` runs: writes `.env` from `.webslice/env.production`,
   installs Composer dependencies without dev packages, checks there is an
   application key, links shared storage, and builds assets with Vite. A failure
   here stops the deploy before anything goes live.
4. The release goes live and starts serving.
5. `.webslice/release.sh` runs: checks `APP_URL` is really this site, caches
   the framework config and routes, then clears and warms the static cache.

Both scripts print their output to the deploy log, under `Activity` on the
website in the Console: `Website Deployment` for the build, `Website Release
Phase` for the release.

The framework caches are built in the release rather than the build because
live deploys clear `bootstrap/cache/*.php` just before the release goes live, so
a config cache built during the build would be deleted before it was used.

## Deploy strategies

Both work, and the choice is about who edits content and whether you need
instant rollback. It can be changed later from the Console.

**Versioned** is the platform default. Each deploy creates a complete new copy
of the site and moves a `live` symlink onto it. The switch happens all at once,
with no half deployed state, and previous versions stay for instant rollback.
Anything written into the application directory at runtime is gone on the next
deploy unless it is in shared storage.

- Best when content is authored in git and deployed, which is how this starter
  is set up.
- Costs more storage, one full copy per deploy.
- Control Panel *content* edits made on production are lost on the next deploy,
  unless you turn on Statamic's git integration. See
  [editing content in production](#editing-content-in-production). Uploaded
  assets are fine either way: the build puts them in shared storage.

**Live** keeps a single directory and syncs only the files that changed. Files
that your build did not touch are left alone, including anything written on the
live site.

- Best when people edit in the Control Panel on production and you would rather
  not run the git integration.
- No instant rollback: going back means deploying an older commit.
- Stale build caches can survive into a new release, which is why Webslice
  clears `bootstrap/cache/*.php` and `storage/statamic/static` after each live
  deploy. `.webslice/settings.toml` adds `public/static` to that list.

If you have no strong reason either way, start with versioned. It is the
default, the rollback is genuinely useful, and this starter's content lives in
git already.

## Static caching

The single biggest thing you can do for both speed and cost on a serverless
platform. It takes two pieces that have to agree with each other.

**Statamic writes the cache.** With `STATAMIC_STATIC_CACHING_STRATEGY=full`,
each rendered page is written to `public/static` as
`<path>_<query string>.html`.

**Apache serves it.** These lines in `public/.htaccess` return that file
directly, without starting PHP:

```apache
RewriteCond %{DOCUMENT_ROOT}/static/%{REQUEST_URI}_%{QUERY_STRING}\.html -s
RewriteCond %{REQUEST_METHOD} GET
RewriteRule .* static/%{REQUEST_URI}_%{QUERY_STRING}\.html [L,T=text/html]
```

Delete those and the cache files are still written and never read, with no
error to tell you: just a site that quietly costs more and responds slower.

`php please static:warm` in the release script requests every URL so the files
exist before the first visitor arrives. `warm_concurrency` is set to 5 in
`config/statamic/static_caching.php`. Each concurrent request is a serverless
instance, so raising it warms faster and starts more instances at once. Keep it
below the website's concurrency limit.

### What is excluded, and why

Three URLs are listed under `exclude` in `config/statamic/static_caching.php`:

- `/contact`, because a cached page carries a cached CSRF token. By the time
  someone submits the form that token has expired and the submission fails. The
  page renders on each request instead.
- `/sitemap.xml` and `/feed.xml`, because the file cacher names every entry
  `.html` and the rewrite above serves it as `text/html`, so search engines and
  feed readers would get XML under the wrong content type.

Add any other page with a form, a search box or per-visitor content to that
list.

## What survives a deploy

`/mnt/data/website/shared` sits outside the application directory and survives
every deploy. [`webslicehq/statamic-provider`](https://github.com/webslicehq/statamic-provider)
points Statamic at it automatically whenever the `WEBSLICE` environment variable
is set, which the platform does for you. There is nothing to configure.

Handled for you:

| What | Where it goes |
| --- | --- |
| Form submissions | `/mnt/data/website/shared/form-submissions` |
| Logs | `/mnt/data/website/shared/logs` |
| Resized and cropped images | `/mnt/data/website/shared/public/glide-cache`, linked to `public/img` |

The provider also repoints the framework cache and compiled views at `/tmp`,
which is per instance and fast, rather than at the shared filesystem.

### Assets

Uploads made in the Control Panel, along with the `.meta` files Statamic writes
beside them to hold alt text and focal points, go inside the assets container at
`public/assets`. That sits in the deploy directory, which versioned deploys
replace wholesale, so the build points it at shared storage instead:

- Assets committed to git are copied into `/mnt/data/website/shared/public/assets`
  on every build, so git stays the source of truth for anything tracked.
- `public/assets` is then replaced with a symlink to that directory, so uploads
  made on the live site land in shared storage and survive deploys.

Both sources end up in the same place, and you can use either. Two
consequences follow from that:

- Nothing is ever deleted from shared storage. Removing an asset from git does
  not remove it from the live site; delete it in the Control Panel or over SFTP.
- A committed file and an upload with the same name will collide, and the
  committed one wins on the next build.

None of this happens locally, where `public/assets` stays an ordinary directory.

### The application key

Laravel encrypts cookies and sessions with `APP_KEY`, so every release needs the
same one. Setting it in the Console is the more reliable option, but it is not
required: when the build finds no key it generates one and saves it to
`/mnt/data/website/shared/app-key`, then reuses that file on later deploys. So a
site that never sets `APP_KEY` logs everyone out once, on its first deploy,
rather than on every one.

A key set in the Console always wins, because a real environment variable takes
precedence over `.env`. For the same reason the build cannot repair a Console
key that is not a valid Laravel key, so it fails the deploy rather than ship a
site that boots and then errors on the first cookie it has to decrypt.

## Databases

Statamic is flat file. Content, users and form submissions are all files, and
nothing in this starter reads from a database.

If you add something that needs one, link a managed database from the Console.
**Do not use SQLite.** Webslice serves your files from network storage shared
between instances, and SQLite's file locking behaves badly on it. `DB_CONNECTION=sqlite` in `.env.example` is a local
convenience and nothing connects to it.

## Editing content in production

Statamic's Control Panel works on Webslice, so you can log in at `/cp` and edit
a live site. What happens next depends on your deploy strategy.

On **live** deploys the edit is written to the deploy directory and stays there,
as long as the same file does not also change in a later build.

On **versioned** deploys the edit is written into the current release and
disappears on the next deploy. Two ways to handle it:

- Make content changes locally and push them, which is the workflow this starter
  assumes.
- Turn on [Statamic's git integration](https://statamic.dev/git-automation) with
  `STATAMIC_GIT_ENABLED=true`, so Control Panel edits are committed and pushed
  back to the repository. This needs a deploy key with **write** access, which
  is more than the read-only key a deploy needs.
