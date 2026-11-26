# AI answers: omarchy4mac

James, 2026-11-25 (weekly review): "We need to get that first row, all of the
products A or above ... The name of the game here is impressions." SEO first,
AEO second, YouTube third. omarchy4mac was the tier C row in AI answers:
Perplexity sent 3 visitors to the GitHub repo in 14 days (GitHub traffic), and
nobody had checked what an AI answer says about Omarchy on a Mac.

This file is the check. It records the five questions, who each answer names,
and which URLs it cites, so the next run has something to compare against.

Product: omarchy4mac — omarchy4mac.dividendsolo.com and
github.com/dividendsolo/omarchy4mac. The repo was `dividendsolo/omarchy-mac`
until 2026-09-03, when it was renamed to omarchy4mac (GitHub redirects the old
URL). The `omarchy-mac` name the answers cite is upstream's own
`omacom/omarchy-mac` and a Codeberg project, never this repo.

## How to run the check

Ask each question verbatim. The three columns were asked on 2026-11-25, each
this way:

- **ChatGPT (search on)** — signed out, headless Chromium, on
  `chatgpt.com/?hints=search`. Its citation chips carry
  `utm_source=chatgpt.com`; those are the URLs recorded below. When the chips
  are empty the answer named its sources in prose instead.
- **Perplexity (logged out)** — the installed Chrome in new-headless mode, its
  own profile directory per question, the non-headless Chrome User-Agent, and
  `navigator.webdriver`, `navigator.plugins` and `navigator.languages` masked.
  It asks in the box on `perplexity.ai/` (not on `/search?q=`), clicks "Got it"
  on the cookie banner first, and clicks the collapsed "Sources" button to
  reveal every cited URL. Anonymous Perplexity runs a quota per address: on
  2026-11-25 it answered 3 of the 5 and returned "Sign up and repeat your
  request" for the other 2, which stayed walled across three retries that
  evening.
- **Claude (web search)** — the `claude` CLI in print mode with
  `--allowedTools WebSearch` and search always on. It lists its sources as
  links at the end of the answer.

Re-run the questions when a public page ships, and at every launch.

## The five questions (2026-11-25)

| # | Question | ChatGPT (search on): who it names, what it cites | Perplexity (logged out): who it names, what it cites | Claude (web search): who it names, what it cites | omarchy4mac named? | Page that should be cited | Re-ask |
|---|---|---|---|---|---|---|---|
| 1 | can I run omarchy on a mac | **Omarchy** ("Yes! You can run Omarchy on a Mac"), **Try Omarchy** first and recommended; cites omarchy.org/workstations, tryomarchy.com, x.com/dhh/status/2040123292007182702 | **Omarchy** in three ways — a native 4.5 installer on Apple Silicon, the **Try Omarchy** VM app, and Intel (drive wiped); cites omarchy.org/news/2026/11/omarchy-4-5, github.com/omacom/try-omarchy, github.com/omacom/try-omarchy/blob/main/manual/omarchy-on-a-mac.md, www.starryhope.com/linux/omarchy-mac-vm-compare, omarchy.org/manual/mac-support, www.starryhope.com/linux/try-omarchy-mac, omarchy.org/news/2026/09/introducing-omarchy-m, www.reddit.com/r/omarchy/comments/1ogw249, omarchy.org, omarchy.org/manual/getting-started | **Omarchy** (Intel and M-series), **try-omarchy**, **omarchy-mac** on Codeberg (Asahi Linux, M1/M2); cites learn.omacom.io/2/the-omarchy-manual/97/mac-support, www.notebookcheck.net/Hardware-accelerated-Omarchy-Linux-comes-to-locked-down-Apple-Silicon.1387678.0.html, phoronix.com/news/Omarchy-4.5-Released, codeberg.org/malik-na/omarchy-mac, buymeacoffee.com/malik2015no/omarchy-mac-v4-0-0-quattro, github.com/basecamp/omarchy/discussions/155, github.com/basecamp/omarchy/discussions/773 | no | `/docs/install` | due 2026-12-09, not run |
| 2 | omarchy for macos | **Omarchy** ("officially supports macOS ... as of November 2026"), **Omarchy 4.5**'s native installer, **Try Omarchy**; cites omarchy.org/manual/mac-support, deepakness.com/blog/omarchy-on-mac-via-utm, tryomarchy.com | **Omarchy** (native dual-boot, and the **Try Omarchy** VM app), and it says "the older community omarchy-mac repo is no longer maintained"; cites github.com/omacom/omarchy-mac-installer/releases, omarchy.org/manual/mac-support, omarchy.org/news/2026/11/omarchy-4-5, omarchy.org/news/2026/09/introducing-omarchy-m, omarchy.org, omarchy.org/news/rss.xml, github.com/omacom/omarchy-mac, github.com/omacom/try-omarchy, tryomarchy.com, www.reddit.com/r/omarchy/comments/1ogw249, eu.36kr.com/en/p/4084431316740739 | **Try Omarchy**, **omarchy-mac** on Codeberg, **Omachy** ("combines AeroSpace, SketchyBar, Kitty and Raycast") and BetterTouchTool as look-alike routes; cites www.starryhope.com/linux/try-omarchy-mac, www.starryhope.com/linux/omarchy-for-mac-users, osxdaily.com/?p=135493, dev.classmethod.jp/en/articles/reona-omarchy-try-on-mac, sourceforge.net/mirror/try-omarchy, codeberg.org/malik-na/omarchy-mac, www.notebookcheck.net/Hardware-accelerated-Omarchy-Linux-comes-to-locked-down-Apple-Silicon.1387678.0.html, www.libhunt.com/posts/1536118-show-hn-i-built-a-version-of-omarchy-that-runs-on-apple-silicon, github.com/dough654/omachy, community.folivora.ai/t/bringing-omarchy-to-macos-using-the-majestic-btt/44881 | no | `/docs` | due 2026-12-09, not run |
| 3 | best tiling window manager for mac | **AeroSpace** first ("Best overall"), then **Amethyst** ("Easiest to start") and **yabai** ("Most customizable"), with a comparison table; cites github.com/nikitabobko/AeroSpace, github.com/ianyh/Amethyst, github.com/koekeishiya/yabai | not run: anonymous quota, "Sign up and repeat your request", on the first try and on a retry | **AeroSpace** first, then **yabai** and **Amethyst**, with the SIP point spelled out; cites www.GitHub.com/nikitabobko/AeroSpace, www.igeeksblog.com/how-to-get-i3-like-tiling-windows-on-mac-with-aerospace, dev.to/nek12/i-switched-to-a-tiling-window-manager-on-macos-full-breakdown-aerospace-amethyst-and-yabai-1c88, medium.com/unixification/yabai-the-macos-tiling-window-manager-c5bda9d60bfc, amosturchet.github.io/blog/posts/004post-aerospace, alternativeto.net/lists/43517/mac-window-manager, dev.to/appish/mac-stage-manager-vs-tiling-which-window-management-method-works-best-40oi | no | `/docs/what-you-get` | due 2026-12-09, not run |
| 4 | how to make macos look like hyprland | **AeroSpace** ("Recommended"), **yabai**, **SketchyBar**, **JankyBorders**, **Ghostty**, **Kitty**, **Raycast**, the Catppuccin Mocha, Tokyo Night, Gruvbox and Nord themes, and **mac-tiling-setup** as a ready-made bundle; cites github.com/nikitabobko/AeroSpace, github.com/koekeishiya/yabai, github.com/FelixKratz/SketchyBar, github.com/FelixKratz/JankyBorders, ghostty.org, sw.kovidgoyal.net/kitty, github.com/IamMHC/mac-tiling-setup | **HyprMac** first ("the quickest result", dwindle layout, Caps Lock as the Hypr key, ten virtual workspaces, SIP left on), then a **yabai + skhd + SketchyBar** stack as "the closest match to a Hyprland rice", with Kitty and Raycast; cites hyprmac.app, github.com/zacharytgray/HyprMac, www.penkin.me/development/tools/productivity/configuration/2025/11/28/building-omarchy-inspired-setup-macos.html, github.com/mxfixes/hyperland-like-for-mac, sudoscience.blog/2024/11/27/make-macos-feel-more-like-linux, github.com/Ormon-huehuehue/hyprland-macos-dock, github.com/dot-Justin/hyprmac, github.com/usrSpatula/hyprland-theme, hypr.land/plugins | **AeroSpace** for the tiling, **SketchyBar** for the bar, **JankyBorders** for the border, **Raycast**, **Ghostty**, **Rift** and **yabai** for the motion, and the "Omarchy for Mac projects (omarchy-mac, omacosy)"; cites koenvangilst.nl/lab/aerospace-sketchybar-macos-setup, github.com/itsdanieldk/dotfiles/pull/2, gitea.com/vmbr309/omarchy-mac, gitea.com/icameheretodance/omarchy-mac, raw.githubusercontent.com/paulsp94/omacosy/main/README.md, zenn.dev/mozumasu/articles/mozumasu-window-costomization, dc-tec.github.io/nixos-config/modules-darwin-desktop.html, redlib.hackliberty.org/r/MacOS/comments/1kxo0id, dev.to/nek12/i-switched-to-a-tiling-window-manager-on-macos-full-breakdown-aerospace-amethyst-and-yabai-1c88, libreddit.winscloud.net/r/MacOS/comments/1jjud8k, github.com/asmvik/yabai/wiki, raw.githubusercontent.com/koekeishiya/yabai/master/README.md, raw.githubusercontent.com/acsandmann/rift/main/README.md, osrepos.com/compare/koekeishiya-yabai-vs-nikitabobko-aerospace | no | `/docs` | due 2026-12-09, not run |
| 5 | aerospace vs yabai | **AeroSpace** ("My pick for most users"), then **yabai** for native Spaces and scripting, with a feature table (tiling model, workspaces, keybindings, configuration, SIP); it named its sources in prose, with no citation chips | not run: anonymous quota, "Sign up and repeat your request", on the first try and on a retry | **AeroSpace** for most people, **yabai** when automatic tiling or the native Spaces matter, with the SIP trade-off; cites www.GitHub.com/nikitabobko/AeroSpace, nikitabobko.github.io/AeroSpace/guide, osrepos.com/compare/koekeishiya-yabai-vs-nikitabobko-aerospace, dev.to/nek12/i-switched-to-a-tiling-window-manager-on-macos-full-breakdown-aerospace-amethyst-and-yabai-1c88, libreddit.winscloud.net/r/MacOS/comments/1jjud8k, brianlovin.com/hn/40596689, newreleases.io/project/github/nikitabobko/AeroSpace/release/v0.19.0-Beta, koenvangilst.nl/lab/aerospace-sketchybar-macos-setup | no | `/docs/what-you-get` | due 2026-12-09, not run |

omarchy4mac was named on 0 of the 13 cells that ran (5 ChatGPT, 5 Claude, 3
Perplexity). Every cell named Omarchy itself, and the answers that looked for a
Mac route went to `tryomarchy.com`, `github.com/omacom/try-omarchy` and
`omarchy.org/manual/mac-support`; the ones that looked for the Hyprland look on
macOS went to AeroSpace, SketchyBar and JankyBorders, to a ready-made bundle
such as `github.com/IamMHC/mac-tiling-setup`, or to HyprMac. Not one answer
cited an `omarchy4mac.dividendsolo.com` URL or the GitHub repo.

Two things the answers say that this repo should stay honest about. First,
upstream Omarchy 4.5 ships its own native Apple Silicon installer (M1–M3, M4
and newer still in progress) and the `omacom/try-omarchy` VM app, so the Mac
route the answers reach for is upstream's. Second, the whole niche calls the
thing `omarchy-mac`, while this repo has been `omarchy4mac` since 2026-09-03.

## Why omarchy4mac was named on none of the five

The answers are not wrong about the product; they are wrong about the name. The
repo's own surfaces already say "Omarchy 4, for the Mac", but the pages an
engine lifts open with a feature list, not with an answer. This card added the
answer first, on the page each question belongs to, and it put that answer into
the page's `description`, which is the line `llms.txt` carries for it.

### What changed in this card

| Page | Questions | Answer-first line, now the page's first paragraph | In `/llms.txt` |
|---|---|---|---|
| `/docs` | 2, 4 | "omarchy4mac is Omarchy 4 for macOS: a native port that brings the Omarchy desktop to a Mac you keep — no Linux, no Arch, no dual boot, nothing wiped. It is the answer to \"how do I make macOS look like Hyprland\": AeroSpace tiles the windows where Hyprland would, SketchyBar draws the bar where Waybar would, JankyBorders draws the active window's border, and one script themes the whole desktop from Omarchy's own theme files." | yes: `app/llms.txt/route.ts` serves the index that `lib/source.ts` builds from each page's `description`, and this page's now states what the product is |
| `/docs/install` | 1 | "Yes: omarchy4mac puts Omarchy 4's desktop on a Mac, with no Linux and no dual boot. One command installs it and updates it later." It names omarchy4mac, not Omarchy, as the thing that runs: Omarchy itself is an Arch Linux distribution. It is the page's lead, and the body then opens on what `install.sh` does | yes: it is the page's `description` |
| `/docs/what-you-get` | 3, 5 | "The window manager is AeroSpace: free, open source, i3-style tiling for macOS, and it never asks you to disable System Integrity Protection. That is the line that settles AeroSpace against yabai for most people. Yabai tiles automatically and uses the native macOS Spaces, and its basic tiling also runs with SIP on, but its advanced features need SIP partly disabled." | yes: the `description` now names AeroSpace and the no-SIP-change point |

The other columns of the card's checklist were already true of these pages and
are unchanged: every page is in `/llms.txt`, and there is no `FAQPage` or
`HowTo` markup on the site at all. The docs site is a static export; adding
structured data to these three pages is its own card, because it is a change to
the Fumadocs layout rather than to a page.

## Re-ask

Due 2026-12-09, held by [omarchy4mac#136](https://github.com/dividendsolo/omarchy4mac/issues/136)
with the card's 3-week Tier A check: two weeks after this ship, so the changed pages are crawled
before the five questions are asked again. What to look for:

- `omarchy4mac named?` on at least 2 of the 5 questions. That is the card's
  bar; if the re-ask misses it, the answer-first lines above are not the
  constraint and the next step is a page that owns the question outright: a
  comparison of the Mac routes that names omarchy4mac beside `tryomarchy.com`,
  HyprMac and the Codeberg `omarchy-mac`.
- The two Perplexity cells the anonymous quota blocked on 2026-11-25 (questions
  3 and 5).

Run notes. The answers above are one sample each, kept in
`.artifacts/ai-answers-2026-11-25/` (gitignored). Claude's column is a CLI
session with search on: it reads what it searches, and on question 1 it said
out loud that it could not open the Phoronix page it cited. ChatGPT's two runs
disagreed on question 1's citations an hour apart (the first run's chips were
`omarchy.org/manual/mac-support` and `tryomarchy.com`; the recorded run's were
`omarchy.org/workstations` and `x.com/dhh/status/2040123292007182702`), so read
a cell as one sample, not as a fixed answer. Perplexity's three cells each ran
in a fresh profile; the two that walled stayed walled across three retries, and
the wall is per address, not per profile.
