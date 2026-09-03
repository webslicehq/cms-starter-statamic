#!/bin/bash
#
# Webslice build script. Runs during the deploy, before the release goes live,
# in the directory that is about to become the site.
#
# Add `set -x` if you need to see every command in the deploy log.

set -euo pipefail

echo "==> Building for Webslice"

# ---------------------------------------------------------------------------
# Environment
# ---------------------------------------------------------------------------
# Production defaults, not the local ones in .env.example. Console env vars are
# real environment variables and override anything in here, so secrets and
# per-site config stay in the Console.
cp .webslice/env.production .env

# ---------------------------------------------------------------------------
# PHP dependencies
# ---------------------------------------------------------------------------
composer install \
    --no-interaction \
    --no-progress \
    --no-dev \
    --prefer-dist \
    --optimize-autoloader

# ---------------------------------------------------------------------------
# Application key
# ---------------------------------------------------------------------------
# Laravel encrypts cookies and sessions with this, so every release needs the
# same one. A key that changes rotates that encryption and logs everyone out of
# the Control Panel.
#
# Three places it can come from, best first:
#   1. APP_KEY in the Console. Nothing on the platform can lose it, so this is
#      the one to set for a production site.
#   2. A key an earlier deploy generated and left in shared storage, which
#      outlives the release that made it. This is what makes setting one
#      optional: you can deploy first and never think about it.
#   3. Generated here, on the first deploy that finds neither, then saved to
#      shared storage so the next deploy takes route 2.
#
# Sessions break on the deploy that moves between those, not on every deploy.
APP_KEY_FILE=/mnt/data/website/shared/app-key

# Laravel takes a raw key or a base64: one, and the cipher fixes the length. A
# key of the wrong length boots fine and then fails on the first cookie it has
# to decrypt, so check the length here rather than find out at runtime.
key_is_valid() {
    php -r '
        $key = $argv[1] ?? "";
        if (str_starts_with($key, "base64:")) {
            $key = base64_decode(substr($key, 7), true);
            if ($key === false) {
                exit(1);
            }
        }
        exit(in_array(strlen($key), [16, 32], true) ? 0 : 1);
    ' "$1"
}

read_env_key() {
    grep -E '^APP_KEY=.+' .env | head -n1 | cut -d= -f2- || true
}

if [ -n "${APP_KEY:-}" ]; then
    # A Console env var wins over .env at runtime, so a broken one cannot be
    # repaired from here. Say so rather than deploy a site that boots and then
    # fails on the first encrypted cookie.
    if key_is_valid "$APP_KEY"; then
        echo "==> Application key set in the Console"
    else
        echo "==> ERROR: APP_KEY in the Console is not a valid Laravel key." >&2
        echo "    Run 'php artisan key:generate --show' locally and paste that" >&2
        echo "    value, or remove it and let the deploy generate one." >&2
        exit 1
    fi
else
    generated=false

    if key_is_valid "$(read_env_key)"; then
        echo "==> Application key already set"
    elif [ "${WEBSLICE:-}" = "1" ] && [ -s "$APP_KEY_FILE" ] && key_is_valid "$(cat "$APP_KEY_FILE")"; then
        echo "==> Reusing the application key kept in shared storage"

        # Not `sed -i`, whose arguments differ between GNU and BSD. Writing the
        # result back through cat keeps .env's own permissions and inode.
        tmp="$(mktemp)"
        sed "s|^APP_KEY=.*|APP_KEY=$(cat "$APP_KEY_FILE")|" .env > "$tmp"
        cat "$tmp" > .env
        rm -f "$tmp"
    else
        echo "==> No application key found. Generating one."
        echo "    This logs everyone out of the Control Panel once. It is kept"
        echo "    in shared storage afterwards, so later deploys reuse it. To"
        echo "    hold the key yourself, run 'php artisan key:generate --show'"
        echo "    locally and set APP_KEY in the Webslice Console."
        php artisan key:generate --no-interaction
        generated=true
    fi

    # key:generate reports failures but still exits 0, so set -e misses them,
    # and a release with no usable key breaks every session and the CP login.
    # Checked before the key is saved, so a bad one is not handed to every
    # future deploy as well.
    if ! key_is_valid "$(read_env_key)"; then
        echo "==> ERROR: no usable application key was written to .env." >&2
        exit 1
    fi

    # Outside the document root, unlike shared/public, so it is not reachable
    # over HTTP. WEBSLICE is set by the platform, so this is skipped locally,
    # where a key per run does no harm.
    if [ "$generated" = true ] && [ "${WEBSLICE:-}" = "1" ]; then
        mkdir -p "$(dirname "$APP_KEY_FILE")"
        (umask 177; read_env_key > "$APP_KEY_FILE")
        echo "==> Saved it to shared storage for the next deploy"
    fi
fi

# ---------------------------------------------------------------------------
# Persistent storage
# ---------------------------------------------------------------------------
# The provider points logs, form submissions and the Glide cache at
# /mnt/data/website/shared itself. Assets it does not touch, so we do it here.
# WEBSLICE is set by the platform, so this is skipped locally.
if [ "${WEBSLICE:-}" = "1" ]; then
    SHARED=/mnt/data/website/shared
    mkdir -p "$SHARED/logs" "$SHARED/form-submissions" \
             "$SHARED/public/glide-cache" "$SHARED/public/assets"

    # Control Panel uploads, and the .meta sidecars holding their alt text, are
    # written inside the assets container, which versioned deploys replace. Seed
    # shared storage from git, then link the container at it, so both sources
    # end up in the same place. See docs/how-it-works.md for the trade-offs.
    if [ -d public/assets ] && [ ! -L public/assets ]; then
        cp -R public/assets/. "$SHARED/public/assets/"
        rm -rf public/assets
    fi

    ln -sfn "$SHARED/public/assets" public/assets
fi

# ---------------------------------------------------------------------------
# Front end assets
# ---------------------------------------------------------------------------
npm ci --no-audit --no-fund
npm run build

echo "==> Build complete"
