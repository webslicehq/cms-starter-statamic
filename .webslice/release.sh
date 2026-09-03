#!/bin/bash
#
# Webslice release script. Runs after the new release is live, against the live
# directory.
#
# Framework caches are built here rather than in the build because live deploys
# clear bootstrap/cache/*.php just before the release goes live. Nothing warms
# the Stache or compiles views: the provider points both at /tmp, which is per
# instance and discarded, so doing it on this container achieves nothing.

set -euo pipefail

echo "==> Releasing on Webslice"

# Settings arrive either as Console env vars or in .env, written by the build
# from .webslice/env.production. The shell only sees the first kind, so read
# them through Laravel to get the same precedence PHP will use.
config_value() {
    php -r 'require "vendor/autoload.php"; $app = require "bootstrap/app.php"; $app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap(); echo config($argv[1]) ?? "";' "$1"
}

# ---------------------------------------------------------------------------
# Check the environment before touching anything
# ---------------------------------------------------------------------------
# The site is already live, so everything below writes somewhere it reads from.
# Clear the config cache first or these reads get the previous release's values.
php artisan config:clear

APP_URL_VALUE="$(config_value app.url)"
STRATEGY="$(config_value statamic.static_caching.strategy)"

# static:warm builds its URL list from APP_URL and reports success even when
# every request fails, so a wrong value is a green deploy with a cold site.
if [ -z "$APP_URL_VALUE" ] || [ "$APP_URL_VALUE" = "http://localhost" ]; then
    echo "==> ERROR: APP_URL is not set to this site's URL (resolved: '$APP_URL_VALUE')." >&2
    echo "    Set APP_URL under Env Vars in the Webslice Console, then redeploy." >&2
    echo "    Nothing has been changed." >&2
    exit 1
fi

# A scheme is required. Laravel reads a bare domain as a path, not a host, and
# silently falls back to http://localhost for every generated URL.
case "$APP_URL_VALUE" in
    http://*|https://*) ;;
    *)
        echo "==> ERROR: APP_URL is missing its scheme (resolved: '$APP_URL_VALUE')." >&2
        echo "    Use the full URL, for example https://$APP_URL_VALUE, then redeploy." >&2
        echo "    Nothing has been changed." >&2
        exit 1
        ;;
esac

# ---------------------------------------------------------------------------
# Framework caches
# ---------------------------------------------------------------------------
php artisan config:cache
php artisan route:cache

# ---------------------------------------------------------------------------
# Static cache
# ---------------------------------------------------------------------------
# Statamic writes a cache entry only when one is absent, so after a clear the
# first render of each URL owns it until the next clear. Warming straight after
# clearing is what makes that first render this script's, rather than whichever
# request happens to arrive first.
if [ -z "$STRATEGY" ]; then
    echo "==> Static caching is off, nothing to warm."
    echo "    Set STATAMIC_STATIC_CACHING_STRATEGY=full to serve cached HTML"
    echo "    without booting PHP."
else
    echo "==> Clearing and warming the static cache ($STRATEGY) at $APP_URL_VALUE"

    php please static:clear

    # Exits 0 even when every URL fails, so trust the count below rather than
    # the exit code, and read the per-URL lines in the deploy log when it is off.
    php please static:warm

    echo "==> Cached $(find public/static -type f 2>/dev/null | wc -l | tr -d ' ') pages"
fi

echo "==> Release complete"
