# Editing the site

How to change content, fields and templates in this starter.
[`README.md`](../README.md) covers getting it running, and
[`how-it-works.md`](how-it-works.md) covers the Webslice specific parts.

- [Where things live](#where-things-live)
- [Adding a page](#adding-a-page)
- [Adding a blog post](#adding-a-blog-post)
- [Adding a field](#adding-a-field)

## Where things live

Statamic keeps everything in files, not a database. The Control Panel at `/cp`
and your editor are two ways at the same thing: create a page in the browser and
a markdown file appears in `content/`, ready to commit.

| To change | Edit |
| --- | --- |
| Words on a page | `content/collections/pages/<slug>.md` |
| A blog post | `content/collections/blog/<date>.<slug>.md` |
| What fields a page or post has | `resources/blueprints/collections/` |
| How something looks | `resources/views/` |
| Site description, footer, contact email | `content/globals/default/site_settings.yaml` (the footer is markdown, so it can hold links) |
| The main menu | `content/trees/navigation/main.yaml` |

The directories those sit in:

| Path | What it does |
| --- | --- |
| `content/` | Pages, blog posts, navigation and globals, as flat files. |
| `resources/blueprints/` | The field definitions behind each content type and the contact form. |
| `resources/views/` | Templates, written in Statamic's own template language, Antlers. Includes `sitemap.antlers.xml` and `feed.antlers.xml`. |
| `resources/forms/contact.yaml` | The contact form: where submissions go, and the hidden field used to catch bots. |
| `routes/web.php` | Two routes, for the sitemap and the feed. |

The demo content is there to be deleted once you have your own. The part worth
keeping is everything under `.webslice/`, the static caching setup, and the
rewrite rules in `public/.htaccess`.

## Adding a page

Create it in the Control Panel under `Collections` » `Pages`, or add the file
yourself:

```markdown
---
id: <any unique uuid>
blueprint: page
title: Pricing
---
Your content here, in markdown.
```

It is live at `/pricing` as soon as the file exists. Statamic picks the template
from the entry's `template` field, falling back to
`resources/views/default.antlers.html` when there isn't one, which is what the
About page uses.

**New pages do not appear in the menu on their own.** The menu is a separate
navigation, so add the page to it under `Navigation` » `Main navigation`, or in
`content/trees/navigation/main.yaml`. That separation is deliberate: it lets the
menu hold external links and leave pages out, which is why the home page has an
entry in the page tree but not in the menu.

## Adding a blog post

The filename carries the date, and the collection sorts on it:

```text
content/collections/blog/2026-09-14.a-new-post.md
```

Posts need an `intro`, which is used on the blog index, in the RSS feed, and as
the meta description when the SEO tab is empty. A post dated in the future stays
private until that date passes.

## Adding a field

Fields are defined in blueprints. Adding one to
`resources/blueprints/collections/blog/post.yaml` makes it appear in the Control
Panel immediately, but nothing renders it until you add it to the template in
`resources/views/blog/show.antlers.html`.
