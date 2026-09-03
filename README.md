# Statamic starter for Webslice

A working [Statamic](https://statamic.dev) site, set up to deploy to the
[Webslice serverless platform](https://webslice.com) with nothing left to wire
up. Make your own copy, point a Webslice website at it, and the first push
deploys a site that is statically cached, keeps its form submissions between
deploys, and serves most requests without starting PHP.

Statamic is flat file and can render every page ahead of time, which is exactly
what a serverless platform is best at serving. What is here is the configuration
that gets the most out of that.

It ships with a few pages, a blog, a contact form, a sitemap and an RSS feed, as
a working example to replace with your own.

**Contents**

- [Requirements](#requirements)
- [Deploying to Webslice](#deploying-to-webslice)
- [Running it locally](#running-it-locally)
- [Logging in](#logging-in)
- [Further reading](#further-reading)

## Requirements

- PHP 8.3 or newer
- Composer 2
- Node 20.19 or newer (Vite 8 requires `^20.19.0 || >=22.12.0`)
- A Statamic Pro licence for more than one user or any Pro feature. As shipped,
  it runs on the free edition.

Webslice provides the runtime for the deployed site, so these apply to working
on it locally.

## Deploying to Webslice

Five steps, and your site's URL is the only value you have to supply. You do
not need the site running locally first.

### 1. Make your own copy

Use the **Use this template** button at the top of this repository. Pick a name,
and set it private if this is a client site. Webslice deploys from a repository
you control, and you will be committing to yours as you go: your own Control
Panel user, your content, any configuration you change.

Forking works too, if you would rather keep the link upstream and pull in later
changes. One catch: a fork of a public repository is always public, and GitHub
does not let you make it private.

### 2. Create the website

In the [Webslice Console](https://console.webslice.com), create a website with a
PHP 8.3 or newer runtime and a **git deploy**. Deployment method is fixed once
the website is created, so pick git rather than file or SFTP.

Connect your GitHub, GitLab or Bitbucket account, then choose your repository
and the branch to deploy. Webslice picks up `.webslice/settings.toml` from the
repository, so the build and release scripts are configured already.

### 3. Set the environment variables

Under `Env Vars`, add these. They are real environment variables, and Laravel
never overwrites a variable that is already set, so each one takes precedence
over `.webslice/env.production`.

`APP_URL` is the only one you have to set. If a deploy runs before you have set
it, the release phase fails deliberately rather than publish a site whose every
link points at `localhost`. Set it and deploy again.

| Variable | Value | Why |
| --- | --- | --- |
| `APP_URL` | Your live URL, **including `https://`** | Everything generating a URL reads this, and the release warms the cache by requesting it. A bare domain with no scheme resolves to `http://localhost` and breaks every link, so the release refuses to run without one. |
| `APP_NAME` | Your site name | Used in page titles and the RSS feed. |
| `APP_KEY` | Optional. Run `php artisan key:generate --show` **locally** and paste the value | Laravel encrypts cookies and sessions with it. Leave it unset and the first deploy generates one and keeps it in shared storage, so it stays the same afterwards. Set it here to hold the key yourself rather than depend on that file. |
| `STATAMIC_LICENSE_KEY` | Your licence key | Only if you are running Statamic Pro. |

`.webslice/env.production` already sets `APP_ENV=production`, `APP_DEBUG=false`,
`STATAMIC_STATIC_CACHING_STRATEGY=full` and `STATAMIC_STACHE_WATCHER=false`, so
you do not need to repeat those unless you want to change them.

### 4. Run the first deploy

Connecting the repository does not deploy it. Deploys are triggered by pushes to
whichever branch or tag pattern the website watches, and connecting an existing
repository is not a push, so the first one is yours to start: go to `Deploys` and
click `Deploy` on the commit waiting there. Creating a release on GitHub will not
do it either, unless the website is set to watch tags rather than a branch.

Until it finishes you will see Webslice's own placeholder page, saying the site
is ready to go. That is the platform confirming the website exists, not your
Statamic site, and `/cp` is empty for the same reason. It takes a couple of
minutes.

### 5. Replace the default user

The site ships with a Control Panel user, and its password is in this
repository, so anyone who reads this can sign in to an unchanged deployment.

The quickest fix needs nothing installed: go to `/cp` on your new site, sign in
as `admin@example.com` with `changeme123`, and change the password from your
user profile.

> [!WARNING]
> Do that before the site is reachable by anyone else.

On a **versioned** deploy that change lives in the release that is live now, and
the next deploy replaces it with the committed one. [Logging
in](#logging-in) covers making it permanent.

### Checking it worked

Deploy output is under `Activity` on the website in the Console: `Website
Deployment` for the build, `Website Release Phase` for the release. A good
release ends with the number of pages it cached. If something is wrong,
[troubleshooting](docs/troubleshooting.md) is ordered by how often each cause
comes up.

### Choosing a deploy strategy

You can skip this. The platform default is the right starting point, and the
setting can be changed whenever you like, under `Settings` as `Deploy Strategy`.

**Versioned** is that default: each deploy is a complete new copy with instant
rollback, which suits this starter because it keeps its content in git already.
Choose **live** instead if people will edit in the Control Panel on production
and you would rather not run Statamic's git integration.

The trade offs behind that are in
[deploy strategies](docs/how-it-works.md#deploy-strategies).

## Running it locally

The examples below use [Laravel Valet](https://laravel.com/docs/valet), which is
what the team uses. Anything that serves the `public/` directory works.

```bash
git clone <your-repo> statamic-starter
cd statamic-starter

composer setup          # installs everything, writes .env, builds assets
valet link              # serves it at http://statamic-starter.test
```

`composer setup` copies `.env.example` to `.env` and generates an application
key. If you would rather not use Valet:

```bash
php artisan serve       # http://127.0.0.1:8000
```

Set `APP_URL` in `.env` to whichever URL you end up with. A few things read it,
including the static cache warmer.

To work on the front end with hot reloading, run Vite alongside your server:

```bash
npm run dev
```

### Local defaults

`.env.example` turns static caching **off** locally
(`STATAMIC_STATIC_CACHING_STRATEGY=null`). With it on you would edit a page,
reload, and see the old version, because you would be served a cached file. Turn
it on only when you are specifically testing caching behaviour, and run
`php please static:clear` afterwards.

## Logging in

The repository ships with a Control Panel user, so a fresh clone can sign in at
`/cp` with no setup:

| Email | Password |
| --- | --- |
| `admin@example.com` | `changeme123` |

That password is in this repository, so treat it as public. Fine locally, not
fine on a live site.

### Changing it on the live site

Sign in at `/cp` and change the password from your user profile. Nothing to
install, and it takes a minute.

On the **live** deploy strategy that is the end of it. On **versioned** deploys
the rewritten user file lives in the release that is currently live, and the
next deploy replaces it with the one committed in the repository, restoring the
published password. Either replace the user in the repository as below, or turn
on [Statamic's git
integration](docs/how-it-works.md#editing-content-in-production) so Control
Panel changes are committed back.

### Replacing the user in the repository

This is the permanent version. Statamic stores users as files, so a user you
commit deploys with the site and survives every deploy:

```bash
php please make:user
git rm users/admin@example.com.yaml
git commit -m "chore: replace the default control panel user"
git push
```

Run that on your own machine. The platform gives you SFTP but no shell, which is
why a user gets committed rather than created there.

### Requiring two factor authentication

Worth turning on if a default password might ever be left in place. In
`config/statamic/users.php`:

```php
'two_factor_enforced_roles' => ['super_users'],
```

It is off by default here, because it makes every fresh clone enrol an
authenticator app before it can be used.

## Further reading

In this repository:

- [How this starter works on Webslice](docs/how-it-works.md) covers the files
  that are specific to the platform, the deploy sequence, deploy strategies,
  static caching, which directories survive a deploy, and editing content on the
  live site.
- [Editing the site](docs/editing-the-site.md) covers where content, fields and
  templates live, and how to add a page, a blog post or a field.
- [Troubleshooting](docs/troubleshooting.md) covers the problems that come up
  most, starting with `APP_URL`.

Elsewhere:

- [Statamic on Webslice](https://docs.webslice.com/serverless/cms-guides/statamic/)
- [Webslice serverless documentation](https://docs.webslice.com/serverless/overview/)
- [Statamic documentation](https://statamic.dev)
