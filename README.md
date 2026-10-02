<a name="readme-top"></a>

[![App Build](https://github.com/BadIdeaLab/comicdex/actions/workflows/flutter-workflow-app.yml/badge.svg)](https://github.com/BadIdeaLab/comicdex/actions/workflows/flutter-workflow-app.yml)
[![Backup Server Build](https://github.com/BadIdeaLab/comicdex/actions/workflows/flutter-workflow-windows.yml/badge.svg)](https://github.com/BadIdeaLab/comicdex/actions/workflows/flutter-workflow-windows.yml)
[![MIT License][license-shield]][license-url]

<br />
<div align="center">
  <h3 align="center">nhviewer-universal</h3>

  <p align="center">
    A Flutter rewrite of NHViewer. <br />
    An offline-first reader: an on-device tag catalog with instant search, resumable
    downloads you can read without a connection, recommendations and taste analysis
    built from what you actually keep, and LAN backup of the whole library to your
    own machine.
    <br />
    <br />
    <a href="https://github.com/BadIdeaLab/comicdex/issues">Report Bug</a>
    ·
    <a href="https://github.com/BadIdeaLab/comicdex/issues">Request Feature</a>
  </p>
</div>

<table align="center">
  <tr>
    <td align="center"><img src="./readme-asset/home-feed.png" width="260" alt="Home feed and search"><br/><sub>Home feed & search</sub></td>
    <td align="center"><img src="./readme-asset/tags-character.png" width="260" alt="Tag catalog instant search"><br/><sub>Tag catalog — instant search</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="./readme-asset/downloads-list.png" width="260" alt="Downloads list view"><br/><sub>Downloads — list view</sub></td>
    <td align="center"><img src="./readme-asset/downloads-grid.png" width="260" alt="Downloads grid view"><br/><sub>Downloads — grid view</sub></td>
  </tr>
</table>

---

## Features

### Browsing and search

- Home feed with search, popularity sorting, and language-aware fallback queries
- Offline tag catalog with instant cross-category search and multi-select across
  tag / language / parody / character / artist, ranked by how common each tag is
- Blocked tag list that applies to every search, not just the one in front of you
- Language badge on each cover, read from the listing's own tag ids — no extra requests
- Per-tab scroll position and a refresh button, so returning to the feed does not
  throw away what you had already scrolled through

### Reading

- Vertical reader with tap zones, page-jump bar, and configurable prefetch
- Reading position remembered per comic, with a one-tap way back to page one
- End-of-comic overlay and, on the page past the last one, comics from your own
  library that genuinely resemble the one you just finished
- Optional look on the site for more like it, excluding everything you already have
- Favourite and language are visible on each recommendation, and reachable after
  opening one

### Downloads and offline reading

- Queue with paused, failed, and completed jobs, resumable page by page
- Repair a single download or scan the whole library for missing pages and covers
- Multi-select download from Favourites, skipping what is already downloaded and
  throttling requests so the site is not hammered
- Offline reader that serves pages from local files
- Search by title or tag (including translated tag names), filter by tag chips, and
  sort by date / title / author / popularity / last read / taste
- Grid or list view, remembered between sessions
- "Open something random", weighted so that what you have not read in a while comes
  up more often — without ever excluding anything outright

### Collections and tracking

- `Favorite / Next / History` collections, with multi-select
- Favourites synced from your nhentai account, incrementally: it stops as soon as it
  reaches galleries it already knows about
- Track artists and be told when they publish, with an in-app bell. Checks are
  foreground-only and rate-limited to fewer than two requests an hour however many
  artists you follow

### What you actually read

- Tag preference ranking built from the comics you keep, smoothed so a tag seen three
  times cannot top the chart
- Taste badges on comics matching the tags you keep — scored against your own library
  rather than against what is merely popular
- Analysis page: tag coverage, the full ranking, frequent tag combinations, and which
  tags you tend to collect together

### Backup and restore

- Mirror the whole download library and database to a desktop server over your LAN
- Pair by QR code or PIN; transfers are incremental and can be paused and resumed
- An interrupted restore is detected on the next launch rather than left looking normal

### Platform

- Android and iOS, with a Windows desktop server for backups
- English and Traditional Chinese interface
- Glassmorphism-styled UI across reader, screens, and sheets, with cross-platform
  performance tuning
- CI builds Android and iOS from the same commit and publishes them together

<p align="right"><a href="#readme-top">‣ back to top</a></p>

## Login

Browsing and reading don't require an account. You only need to log in if you want to sync
your nhentai favorites into the Collections tab.

1. Log into your account on [nhentai.net](https://nhentai.net)
2. Open your account settings on the site and copy your personal API key
3. In the app, go to **Settings → Set / Update API Key** and paste it in
4. Tap **Sync Favorites Now** to pull your favorites in

<p align="center">
  <img src="./readme-asset/settings.png" width="280" alt="Settings screen with API key and sync options">
</p>

<p align="right"><a href="#readme-top">‣ back to top</a></p>

## Tech Stack

Flutter · Provider · Go Router · Drift + sqlite3 · Dio · Freezed / json_serializable

<p align="right"><a href="#readme-top">‣ back to top</a></p>

## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

<p align="right"><a href="#readme-top">‣ back to top</a></p>

## Contact

This repository (`comicdex`) is an independently maintained, unofficial mirror. It is not
run by, and has no other affiliation with, the original author below.

Original Author: ttdyce - i@ttdyce.com

Upstream Project: [https://github.com/ttdyce/nhviewer-universal](https://github.com/ttdyce/nhviewer-universal)

<p align="right"><a href="#readme-top">‣ back to top</a></p>

## Acknowledgments

- [ttdyce/nhviewer](https://github.com/ttdyce/NHentai-NHViewer)
- [nhentai.net](https://nhentai.net)
- [NHBooks](https://github.com/NHMoeDev/NHentai-android)
- [EhViewer (deprecated)](https://github.com/seven332/EhViewer)
- [rrousselGit/provider](https://github.com/rrousselGit/provider)
- [cfug/dio](https://github.com/cfug/dio)
- [simolus3/drift](https://github.com/simolus3/drift)
- [Baseflow/flutter_cached_network_image](https://github.com/Baseflow/flutter_cached_network_image)
- [fluttercommunity/flutter_launcher_icons](https://github.com/fluttercommunity/flutter_launcher_icons/)
- Flutter

<p align="right"><a href="#readme-top">‣ back to top</a></p>

[license-shield]: https://img.shields.io/github/license/BadIdeaLab/comicdex.svg?style=for-the-badge
[license-url]: https://github.com/BadIdeaLab/comicdex/blob/main/LICENSE.txt
