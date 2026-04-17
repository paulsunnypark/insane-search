English | [한국어](README.ko.md)

# insane-search

> **The scraper that's too stubborn to quit.**

`403`. WAF. CAPTCHA. Empty SPA. Login wall. When every normal tool taps out, insane-search is just getting started. Five probe phases. Auto-installs TLS impersonation. Discovers hidden APIs through a real browser. Tries everything — and for every site that claimed to be "blocked," something always works.

No API keys. No signup. No config. Install, and watch Claude Code stop giving up.

[Quick Start](#quick-start) • [How it works](#how-it-works) • [What's in the index](#whats-in-the-index) • [References](#references) • [Requirements](#requirements)

---

## Quick Start

### 1. Add the marketplace

```
/plugin marketplace add https://github.com/fivetaku/gptaku_plugins.git
```

### 2. Install the plugin

```
/plugin install insane-search
```

### 3. Restart Claude Code

That's it. No config, no API keys, no env vars.

### 4. Start asking

Just talk normally. Blocked sites will be unblocked automatically.

```
"Show me what's trending on r/LocalLLaMA"
"What did @openclaw post on X recently?"
"Search X for posts about insane-search"
"Summarize this YouTube video"
"Search Coupang for under ₩100,000 keyboards"
"Read this Naver blog post for me"
"네이버에서 클로드코드 관련 뉴스 찾아줘"
"Find LinkedIn articles about Claude Code plugins"
```

---

## Why insane-search?

- **It doesn't know the word "blocked"** — No pre-judged "this site can't be accessed" labels. Every site gets the full chain. Coupang? Coupang falls. LinkedIn? Full article body extracted. Yozm? Chrome UA and done
- **Identity spoofing built in** — Phase 2 doesn't just swap TLS fingerprints. It builds a full browser identity: homepage cookie warming, referrer chains, locale-matched headers. Sites like fmkorea (HTTP 430) and LinkedIn (login wall) fall to this alone
- **Intent routing** — "Fetch this URL" and "Search X for this keyword" are different problems. insane-search routes keywords through WebSearch or Naver Search first, gets URLs, then fetches content. Two-stage pipeline, automatic
- **Installs its own weapons** — Missing `curl_cffi` for TLS fingerprint bypass? Installs it. Missing `feedparser`? Installs it. Missing `yt-dlp`? Installs it. You don't even notice
- **5 probe phases, not 1** — WebFetch → Jina → curl UA/URL variants → TLS impersonation with identity spoofing → real browser. Each phase escalates only when the previous hits a wall
- **Finds hidden APIs** — Phase 3 doesn't just render the page. It watches the browser's network traffic, catches the actual JSON API the site uses internally, and hands it back for reuse
- **Zero setup friction** — No API keys, no OAuth, no developer portals. Everything runs on public endpoints and auto-installable libraries

---

## How it works

When Claude Code needs to fetch a URL, insane-search runs a 4-phase adaptive scheduler. Each phase only runs if the previous phase failed or detected specific blocking signals.

```
Phase 0: Special endpoint index
  ↓ not in index or failed
Phase 1: Lightweight probes (parallel)
  • WebFetch + Jina Reader
  • curl with Chrome / mobile / Googlebot UAs
  • URL variants: m.{domain}, .json, /rss, /feed
  • Sidecar: AMP cache, archive.today, Wayback (low-trust)
  ↓ 403/429/WAF headers/challenge body detected
Phase 2: TLS impersonation + identity spoofing
  • curl_cffi with safari → chrome → firefox
  • Identity spoofing: homepage cookie warming → referrer chain → locale headers
  • Behavioral challenge detection (Akamai _abck) → skip to Phase 3
  • Auto-installs if missing: pip install curl_cffi
  ↓ TLS bypass failed or JS challenge detected
Phase 3: Full browser
  • Playwright MCP (browser_navigate → snapshot → evaluate)
  • Also discovers hidden APIs via network_requests
  ↓ login/paywall detected
Exit: "authentication required" — no amount of phases will fix this
```

**Core principle**: don't pre-exclude any method. Don't skip a method because a dependency is missing — install it and try. Don't skip because a site is "known to be hard" — the site changes, and the method might work now.

Every HTML response is also scanned for OGP tags and JSON-LD structured data — so even partial responses yield titles, summaries, prices, or profile info.

---

## What's in the index

Only special endpoints that the generic chain can't discover on its own. Everything else — Naver blogs, Coupang, LinkedIn, Medium, Korean news sites, Substack, most forums — is handled by the adaptive scheduler without explicit entries.

### Platform-specific APIs

| Platform | Method | Reference |
|----------|--------|-----------|
| X/Twitter | syndication (timeline) + oEmbed (single tweet) + **WebSearch keyword search** | `twitter.md` |
| Reddit | URL + `.json` + Mobile UA | `json-api.md` |
| Bluesky | AT Protocol (`public.api.bsky.app/xrpc/...`) | `public-api.md` |
| Mastodon | Per-instance public API | `public-api.md` |
| Hacker News | Firebase API + **Algolia Search** (`hn.algolia.com/api/v1/search`) | `json-api.md` |
| Stack Overflow | SE API v2.3 | `public-api.md` |
| Lobste.rs / V2EX / dev.to | Public JSON APIs | `json-api.md` |

### Media (CLI tool required)

| Platform | Method | Reference |
|----------|--------|-----------|
| YouTube / Vimeo / Twitch / TikTok / SoundCloud + 1,853 others | `yt-dlp --dump-json` | `media.md` |

### Academic & registry

| Platform | Method | Reference |
|----------|--------|-----------|
| arXiv | Atom API | `public-api.md` |
| CrossRef | REST API | `public-api.md` |
| Wikipedia | REST API | `json-api.md` |
| OpenLibrary | JSON API | `public-api.md` |
| GitHub | `gh` CLI / REST API | `public-api.md` |
| npm / PyPI | Registry API | `json-api.md` |
| Wayback Machine | CDX API | `public-api.md` |

### Korea-specific

| Platform | Method | Reference |
|----------|--------|-----------|
| Naver Search | curl_cffi identity spoofing + `search.naver.com` (통합/블로그/뉴스) | `naver.md` |
| Naver Finance (stock prices) | `api.finance.naver.com/siseJson.naver` (unofficial, no auth) | `naver.md` |

**Everything else flows through Phase 1~3 automatically** — including Coupang (curl_cffi safari), LinkedIn (identity spoofing → JSON-LD full article body), fmkorea (identity spoofing), Medium (Jina), most Korean forums (Jina or curl), and any site with `/rss` or `/feed` endpoints.

---

## References

The skill is organized as a set of reference files, each covering one class of techniques.

| File | Covers |
|------|--------|
| `fallback.md` | Phase 0→3 adaptive scheduler, escalation signals, response validation |
| `jina.md` | Jina Reader (no-key reader at `r.jina.ai`) |
| `json-api.md` | Public JSON APIs (Reddit, HN, dev.to, Wikipedia, npm, PyPI, etc.) |
| `public-api.md` | Bluesky, Mastodon, Stack Exchange, arXiv, CrossRef, OpenLibrary, GitHub, Wayback |
| `media.md` | yt-dlp usage for 1,858 media sites |
| `twitter.md` | Twitter Syndication API + oEmbed + WebSearch keyword search |
| `naver.md` | Naver Search (curl_cffi identity spoofing), blog mobile URLs, Finance JSON API |
| `rss.md` | Korean news RSS (9 outlets), Google News RSS, feedparser, SearXNG |
| `tls-impersonate.md` | curl_cffi multi-target + identity spoofing (cookie warming, referrer chain) + behavioral challenge detection |
| `playwright.md` | Playwright MCP full toolkit (snapshot, evaluate, network_requests) |
| `cache-archive.md` | Google AMP cache, archive.today, Wayback Machine |
| `metadata.md` | OGP, JSON-LD, Schema.org, Next.js RSC payload extraction |

---

## Dependencies

**Required:** Claude Code only.

**Auto-installed when needed** (the skill installs these transparently on first use):

```bash
pip install curl_cffi    # TLS impersonation for WAF-blocked sites
pip install feedparser   # RSS/Atom parsing
pip install yt-dlp       # 1,858 media sites
```

**Optional, improves coverage:**

```bash
brew install gh                      # GitHub (faster than REST API)
claude mcp add playwright -- npx @playwright/mcp@latest   # JS-rendered sites
```

If a dependency is missing, the skill doesn't skip the method — it installs the dependency and tries.

---

## What insane-search is not

- **Not a scraper** — It's a method-selection layer. It uses public APIs and standard techniques
- **Not API-key based** — Everything uses no-auth public endpoints or URL transformations
- **Not a hand-maintained answer key** — The index is minimal (~15 groups). Everything else is discovered by the adaptive scheduler
- **Not bias-forming** — There's no "access denied" list. If a site can be reached, the chain will find the way

---

## Usage

There are no commands. Just talk normally. The skill triggers automatically when a URL is blocked or when accessing platforms that need special handling.

```
"What's on the front page of Hacker News right now?"
→ Firebase API → top stories with scores and comments

"Find AI papers published this week on arXiv"
→ arXiv Atom API with date filter

"Scrape Coupang for laptop deals under $1000"
→ Phase 2: curl_cffi safari → JSON-LD ItemList

"Summarize this Medium article"
→ Phase 1: Jina Reader → clean markdown

"Check what people are saying about Claude Code on Reddit"
→ Reddit JSON API with Mobile UA → posts + top comments

"Search X for insane-search"
→ Intent routing: keyword search → WebSearch(site:x.com) → oEmbed → full tweets

"네이버에서 클로드코드 뉴스 찾아줘"
→ Naver Search (identity spoofing) → news tab → article URLs → Jina Reader

"Find LinkedIn articles about AI agents"
→ WebSearch(site:linkedin.com) → identity spoofing → JSON-LD articleBody
```

---

## License

MIT

---

<div align="center">

**If it's on the web, insane-search is getting in.**

</div>
