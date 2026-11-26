# The searches omarchy4mac answers, and what the volume data says

Pulled 2026-11-25 for the nine queries on omarchy4mac#130. United States,
English.

## The pull

| Query | Google volume (US) | Keyword ideas Ahrefs holds | Bing volume |
|---|---|---|---|
| tiling window manager mac | under 100 | 6 | not reachable |
| aerospace config | under 100 | 34 | not reachable |
| sketchybar config | under 100 | 1 | not reachable |
| sketchybar themes | under 100 | 1 | not reachable |
| aerospace tiling window manager | under 100 | 15 | not reachable |
| hyprland on mac | under 100 | 1 | not reachable |
| mac rice | under 100 | 32 | not reachable |
| omarchy mac | under 100 | 20 | not reachable |
| omarchy m4 | under 100 | 2 | not reachable |

Source: [Ahrefs' free Keyword Generator](https://ahrefs.com/keyword-generator),
which reports a Google monthly volume and a keyword-difficulty score for the
seed and the ideas around it. The second column is the number of keyword ideas
Ahrefs returned for the seed in that pull, which is how wide the longer tail
around a query is in Ahrefs' own database.

## What the numbers can and cannot say

- Every one of the nine queries is **under 100 searches a month** in Ahrefs'
  Google data for the United States. The free tool does not report below 100,
  so the nine cannot be ranked against each other from this source.
- Bing volumes are not reachable from the build machine.
  [Ahrefs' Bing keyword tool](https://ahrefs.com/bing-keyword-tool) answers
  "this tool is under maintenance", and Bing's own keyword research lives in
  Bing Webmaster Tools, behind the site owner's account.
- Exact Google volumes need the Ahrefs API. The Ahrefs connector is in the
  agent catalogue and is not connected, so one authorisation would put exact
  volumes — and the volume of any query — a single call away.

## The rule the five pages were picked by

omarchy4mac#130 asks for the top five of the nine by volume, and no source on
the build machine can order them by volume. So the five were picked by a rule
that does not need the volume column, and it is written down here instead of
being left to taste:

> One page per distinct search intent, for the five intents omarchy4mac has a
> real configuration to answer with.

That gives:

| Page | The search in its title | Why it earns the page |
|---|---|---|
| [Tiling window manager for a Mac](/docs/tiling-window-manager-mac) | tiling window manager mac | The port's whole premise: AeroSpace, its keys and its layout. |
| [AeroSpace config](/docs/aerospace-config) | aerospace config | Ahrefs holds 34 ideas around this seed, and the repo ships the file. |
| [SketchyBar config](/docs/sketchybar-config) | sketchybar config | The repo ships the bar, its 16 plugins and its colour pipeline. |
| [Hyprland on a Mac](/docs/hyprland-on-mac) | hyprland on mac | The question the port exists to answer, with an honest list of what has no port. |
| [Mac rice](/docs/mac-rice) | mac rice | The whole desktop as one thing; 32 ideas around the seed in the pull. |

Four of the nine have no page of their own, on purpose:

- `aerospace tiling window manager` and `sketchybar themes` are the same intent
  as the AeroSpace and SketchyBar pages, so they are covered there rather than
  on a second page that would compete with the first.
- `omarchy mac` and `omarchy m4` are already served by the docs home and by
  [How to make macOS look and feel like Omarchy](https://dividendsolo.com/blog/how-to-make-macos-look-and-feel-like-omarchy)
  on dividendsolo.com, which had the site's only omarchy impressions before
  this change. A second page on the same domain would split them.

## The Search Console floor

Search Console impressions are a floor, not a volume: Google drops every query
it anonymises, so a figure is always a lower bound. The window is 2026-10-27 to
2026-11-23, 28 days ending three days before the pull, because Search Console
runs about three days behind.

| Query | Impressions | Clicks | Position |
|---|---|---|---|
| omarchy m4 | 40 | 0 | 9.0 |
| omarchy mac m4 | 21 | 0 | 7.8 |
| omarchy m4 macbook | 10 | 0 | 8.7 |
| omarchy on m4 | 9 | 1 | 8.6 |
| omarchy mac mini m4 | 4 | 0 | 8.0 |
| omarchy4mac | 4 | 0 | 2.0 |

All of them land on one page on dividendsolo.com. The docs site itself has no
rows yet: its sitemap is not submitted until omarchy4mac#133 runs.

## The readback

Four weeks after the deploy, `vps/scripts/gsc-weekly-pull.py` reads the same two
windows for the docs property. The pages are the test: if they do not have
impressions by then, the pick was wrong and this file says which rule to change.
