---
id: 049ed0c0-9796-43f7-b158-4f6129328c12
blueprint: page
template: home
title: Home
meta_description: 'A Statamic starter for the Webslice serverless platform, with static caching, persistent storage and the deploy scripts already wired up.'
---
A working Statamic site, tuned for Webslice serverless. The two suit each other: Statamic is flat file and can render every page ahead of time, which is exactly what a serverless platform is best at serving. That is set up here already, with pages served without starting PHP, and uploads, form submissions and generated images kept in storage that outlives a deploy.

## Where you are reading this

You are reading this in one of two places.

**Deployed on Webslice.** This page was almost certainly returned by the web server without starting PHP, because the release warmed the static cache before you arrived. [Deploying Statamic to Webslice](/blog/deploying-statamic-to-webslice) covers what the deploy just did, in order, and how to read the logs when a step fails.

**Running on your own machine.** Static caching is off here, so your edits show up as soon as you reload. [What changes when this goes live](/blog/what-changes-when-this-goes-live) covers the settings that differ once it is deployed.

Either way, [how this is put together](/about) covers which parts are doing the work.

## Two ways to edit

Statamic keeps your content in files rather than a database. Open `content/collections/pages/home.md` in your editor, or edit this page in the [Control Panel](/cp) and watch the same file change. Neither is the "real" one.

Which one you use decides how content reaches production. Committing it to git is the default here. Editing on the live site works too, with a caveat covered in [what persists between deploys](/blog/what-persists-between-deploys).

## Further reading

- [Statamic on Webslice](https://docs.webslice.com/serverless/cms-guides/statamic/) covers the platform side: static caching, persistent storage and the deploy scripts.
- [Webslice documentation](https://docs.webslice.com/serverless/overview/) is the rest of the platform, from build scripts to domains and databases.
- [Statamic documentation](https://statamic.dev) is where to go for collections, blueprints and Antlers templates.
- The repository's `README.md` is the practical checklist for deploying and for local setup, with the detail behind it in `docs/`.
