# Troubleshooting

Common problems deploying Statamic to Webslice, most likely first.
[`how-it-works.md`](how-it-works.md) explains the mechanisms these refer to.

- [Pages link to `http://localhost`](#pages-link-to-httplocalhost)
- [The site looks unstyled after a deploy](#the-site-looks-unstyled-after-a-deploy)
- [Everyone is logged out of the Control Panel](#everyone-is-logged-out-of-the-control-panel)
- [The cache was warmed but the site is slow](#the-cache-was-warmed-but-the-site-is-slow)
- [Form submissions are not appearing](#form-submissions-are-not-appearing)
- [Images are regenerated on every deploy](#images-are-regenerated-on-every-deploy)

## Pages link to `http://localhost`

Stylesheets and canonical tags point at `localhost`, and the browser may ask
about accessing other apps or services. That prompt is its local network
protection: the page is telling it to fetch files from the visitor's own machine.

**Almost always `APP_URL` is missing its scheme.** Laravel reads a bare
`example.com` as a path rather than a host, and falls back to `http://localhost`
for every generated URL. Nothing in that chain reports an error. Set the full
`https://example.com` in the Console and redeploy.

The release script refuses to run without a scheme, so check the `Website
Release Phase` log first. If it also says `Static caching is off, nothing to
warm`, the cache is being filled by whichever request arrives first after a
deploy, which on a quiet site can be an internal probe that does not carry your
host.

**Cached pages do not repair themselves.** Statamic writes an entry only when
one is absent, and serves an existing entry rather than re-rendering, so a bad
entry survives every reload. Adding a query string does not help either, because
query strings are ignored for cache keys. Clear and rewarm, which is what a
deploy does:

```bash
php please static:clear && php please static:warm
```

`/contact` and `/sitemap.xml` are excluded from static caching and always render
fresh, which is a quick way to tell the two causes apart. If those are correct
and cached pages are not, the cache is stale rather than the configuration
wrong.

`URL::forceRootUrl()` is not the fix. Statamic matches the request URL against
the site URL to resolve a page, so pinning one host makes every request on any
other host a 404.

## The site looks unstyled after a deploy

The static cache is serving HTML that points at asset filenames from an earlier
build. Check the `Website Release Phase` log to see whether the release ran at
all. `php please static:clear` fixes it either way.

## Everyone is logged out of the Control Panel

The application key changed, so sessions encrypted with the old one no longer
decrypt. Expect this once on a site with no `APP_KEY` set: the first deploy
generates a key, and the `Website Deployment` log says so.

If it happens on **every** deploy, the generated key is not being kept. The
build saves it to `/mnt/data/website/shared/app-key` and reuses it after that,
so look for `Saved it to shared storage` on one deploy and `Reusing the
application key` on the next. Setting `APP_KEY` in the Console takes
precedence over anything the build does.

## The cache was warmed but the site is slow

`static:warm` reports success even when every request fails. Read the per-URL
lines in the log rather than the summary, and check the page count the release
script prints after it.

## Form submissions are not appearing

Check you are on `webslicehq/statamic-provider` 1.1 or newer. Earlier versions
set only the Statamic 4 config key, so on Statamic 5 and 6 submissions went to
the deploy directory and were lost on the next deploy.

## Images are regenerated on every deploy

The image cache only persists while the provider is active. Check `WEBSLICE` is
set and `DISABLE_WEBSLICE_PROVIDER` is not.
