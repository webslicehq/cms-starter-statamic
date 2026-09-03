<?php

use Illuminate\Support\Facades\Route;

/*
 * A sitemap and an RSS feed, rendered from Antlers views. `layout => null`
 * stops the site layout wrapping the XML; the .antlers.xml extension is what
 * makes Statamic send an XML content type.
 *
 * Both are excluded from static caching, because the file cacher names every
 * entry `.html` and Apache would serve them as text/html.
 */

Route::statamic('sitemap.xml', 'sitemap', ['layout' => null]);
Route::statamic('feed.xml', 'feed', ['layout' => null]);
