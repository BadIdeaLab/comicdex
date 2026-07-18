<a name="readme-top"></a>

[![APK Build](https://github.com/BadIdeaLab/comicdex/actions/workflows/flutter-workflow-apk.yml/badge.svg)](https://github.com/BadIdeaLab/comicdex/actions/workflows/flutter-workflow-apk.yml)
[![IPA Build](https://github.com/BadIdeaLab/comicdex/actions/workflows/flutter-workflow-ipa.yml/badge.svg)](https://github.com/BadIdeaLab/comicdex/actions/workflows/flutter-workflow-ipa.yml)
[![MIT License][license-shield]][license-url]

<br />
<div align="center">
  <h3 align="center">nhviewer-universal</h3>

  <p align="center">
    A Flutter rewrite of NHViewer. <br />
    Built with Material 3 / glassmorphism UI, cross-platform support, Drift-based local
    persistence, an offline tag catalog with instant search, and an incremental download
    management flow.
    <br />
    <br />
    <a href="https://github.com/BadIdeaLab/comicdex/issues">Report Bug</a>
    ·
    <a href="https://github.com/BadIdeaLab/comicdex/issues">Request Feature</a>
  </p>
</div>

<!-- Screenshots pending — see conversation: new ones need censoring before they go here. -->

---

## Features

- Home feed with search and language-aware fallback queries
- Local, offline tag catalog with instant cross-category search and multi-select
  (tag / language / parody / character / artist), ranked by popularity
- Blocked tag list — exclude specific tags from all search results
- Collections flow for `Favorite / Next / History`
- Downloads tab for queued, paused, failed, and completed download jobs
- Favorites multi-select download with select-all, already-downloaded skipping, and
  request throttling to avoid rate limits
- Resumable page-by-page downloads with offline asset persistence
- Repair and reload for completed downloads (re-fetch missing pages or full re-download)
- Offline reader entry for completed downloads using local page files
- Download list search across titles and tags, sortable by title/author/popularity/last read
- Reader end-of-comic overlay, page-jump navigation, and navigation expansion on last page
- Vertical reader experience
- Glassmorphism-styled UI across reader, screens, and sheets with cross-platform
  performance tuning
- Android build pipeline and GitHub-hosted unsigned iOS build verification

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
