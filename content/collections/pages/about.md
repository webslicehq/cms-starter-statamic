---
id: 4d2cda0c-3c38-48eb-840a-50f48d62d9a0
blueprint: page
title: 'How this is put together'
meta_description: 'The pieces that make a Statamic site work on serverless hosting, and why each one is here.'
---
Statamic runs on Webslice as it comes. The pieces below are what take it from working to *fast*, and keep whatever is written on a live site around after the next deploy. Each one answers part of that.

## Pages are served as files

Statamic can render each page once and write the HTML to disk. The rewrite rules in `public/.htaccess` then let the web server return that file without starting PHP at all.

This matters more on serverless than on a normal server. You are billed for the requests that run your code, so a request the web server answers on its own costs nothing and returns immediately. The trade is that a cached page is frozen until something clears it, which is why the release script clears and rewarms the whole cache on every deploy.

Pages with a form or anything visitor specific have to opt out, or they break. `/contact` is excluded for exactly that reason: a cached page carries a cached CSRF token, and by the time someone submits the form that token has expired.

## Some directories have to outlive the deploy

The default deploy strategy replaces your whole application directory each time. That is what lets a deploy switch over all at once, with no half-updated state, and roll back instantly. It also means anything written while the site is running is gone on the next deploy.

So five things are pointed at `/mnt/data/website/shared`, which sits outside the deploy:

- Form submissions, so entries you receive stay readable.
- Uploaded assets and their metadata, so images added in the Control Panel survive.
- The generated image cache, so resized images are not rebuilt from scratch.
- Logs, so you can look back further than the last release.
- The application key, when you have not set one yourself, so sessions survive a deploy.

Most of that is done for you by the [Webslice provider](https://github.com/webslicehq/statamic-provider), a composer package that configures Statamic when it detects it is running on the platform.

## The deploy is two scripts

`.webslice/build.sh` installs dependencies and builds assets before anything goes live, so a broken build never reaches visitors. `.webslice/release.sh` runs afterwards, against the live site, and warms the cache.

Both are plain shell scripts in the repository, and `.webslice/settings.toml` tells Webslice where to find them, so a git deploy needs no configuration in the console.

## What is left to you

The pages, the blog, the contact form, the sitemap and the feed are all small on purpose. They are there to show how the pieces fit together, not to be kept, so delete them and build your own once you have had a look.
