<a name="readme-top"></a>

[![APK Build](https://github.com/ttdyce/nhviewer-universal/actions/workflows/flutter-workflow-apk.yml/badge.svg)](https://github.com/ttdyce/nhviewer-universal/actions/workflows/flutter-workflow-apk.yml)
[![Contributors][contributors-shield]][contributors-url]
[![MIT License][license-shield]][license-url]

<br />
<div align="center">
  <h3 align="center">nhviewer-universal</h3>

  <p align="center">
    A Flutter rewrite of NHViewer. <br />
    Built with Material 3, cross-platform support, Drift-based local persistence,
    and an incremental download management flow.
    <br />
    <br />
    <img src="https://storage.googleapis.com/cms-storage-bucket/916809aa4c8f73ad70d2.svg" width="160">
    <br />
    <br />
    <a href="https://github.com/ttdyce/nhviewer-universal/issues">Report Bug</a>
    ·
    <a href="https://github.com/ttdyce/nhviewer-universal/issues">Request Feature</a>
  </p>
</div>

<p>
<img src="./readme-asset/index-and-search.png" alt="Home and search demo" width="270">
<img src="./readme-asset/favorites.png" alt="Downloads and favorites era UI demo" width="270">
<img src="./readme-asset/collections.png" alt="Collections demo" width="270">
</p>

---

## Features

- Home feed with search and language-aware fallback queries
- Blocked tag list — exclude specific tags from all search results
- Collections flow for `Favorite / Next / History`
- Downloads tab for queued, paused, failed, and completed download jobs
- Resumable page-by-page downloads with offline asset persistence
- Repair and reload for completed downloads (re-fetch missing pages or full re-download)
- Offline reader entry for completed downloads using local page files
- Download sorting by latest downloaded, last read, and favorites snapshot
- Reader end-of-comic overlay and navigation expansion on last page
- Vertical reader experience
- Basic list sorting by popularity / uploaded recently
- Android build pipeline and GitHub-hosted unsigned iOS build verification

<p align="right"><a href="#readme-top">‣ back to top</a></p>

## Tech Stack

- Flutter
- Provider
- Go Router
- Drift + sqlite3
- Dio
- cached_network_image / flutter_cache_manager
- flutter_image_compress
- Freezed / json_serializable / build_runner

<p align="right"><a href="#readme-top">‣ back to top</a></p>

## Getting Started

### Prerequisites

- Flutter `3.41.5` recommended to match CI
- Dart SDK compatible with `>=3.10.3 <4.0.0`
- Android Studio or Xcode if you want to build mobile targets locally
- A Flutter editor setup such as [VS Code](https://docs.flutter.dev/get-started/editor)

`pubspec.yaml` currently allows Flutter `>=3.38.4`, but using the same version as CI is the safest choice when generating code and running tests.

### Installation

1. Clone the repo
   ```sh
   git clone https://github.com/ttdyce/nhviewer-universal.git
   cd nhviewer-universal
   ```
2. Install dependencies
   ```sh
   flutter pub get
   ```
3. Generate source files used by Drift / Freezed / JSON serialization
   ```sh
   dart run build_runner build --delete-conflicting-outputs
   ```
4. Run static analysis
   ```sh
   flutter analyze
   ```
5. Run tests
   ```sh
   flutter test
   ```
6. Start the app
   ```sh
   flutter run
   ```

### When To Re-run Code Generation

Run the `build_runner` command again after changing:

- Drift tables or database models
- `@freezed` models
- `@JsonSerializable` / JSON-mapped models

If generated files drift out of sync, build or analysis errors are expected until regeneration is complete.

<p align="right"><a href="#readme-top">‣ back to top</a></p>

## Local Build Commands

### Debug APK

```sh
flutter build apk --debug
```

### Release APK

```sh
flutter build apk --release
```

### iOS build without code signing

```sh
flutter build ios --release --no-codesign
```

This is useful for local verification only. It does not produce a TestFlight-ready artifact by itself.

<p align="right"><a href="#readme-top">‣ back to top</a></p>

## Project Build Flow

The repository currently uses code generation as part of the standard build pipeline:

1. `flutter pub get`
2. `dart run build_runner build --delete-conflicting-outputs`
3. `flutter analyze`
4. `flutter test`
5. platform build command such as `flutter build apk --release`

This is the same order used by the GitHub Actions workflows.

<p align="right"><a href="#readme-top">‣ back to top</a></p>

## GitHub Actions

### Android APK workflow

Workflow file: [.github/workflows/flutter-workflow-apk.yml](./.github/workflows/flutter-workflow-apk.yml)

Current CI steps:

1. Checkout
2. Set up Flutter `3.41.5`
3. `flutter pub get`
4. `dart run build_runner build --delete-conflicting-outputs`
5. `flutter analyze`
6. `flutter test`
7. `flutter build apk --release`

### GitHub-hosted unsigned iOS build

Workflow file: [.github/workflows/flutter-workflow-ipa.yml](./.github/workflows/flutter-workflow-ipa.yml)

If you cannot build iOS locally, you can produce an unsigned IPA from GitHub Actions:

1. Open the `flutter-workflow-ipa` workflow in the Actions tab
2. Trigger it with `workflow_dispatch`
3. Download the `nhviewer-ios-unsigned` artifact after the macOS job finishes

The generated IPA is unsigned. It is useful for remote build verification, but it is not ready for TestFlight or App Store submission.

<p align="right"><a href="#readme-top">‣ back to top</a></p>

## Project Notes

- Local persistence is Drift-based (replaced sqflite in P5); schema migrations are written per-version in `local_database.dart`
- Downloaded files are stored separately from image cache so cache clearing does not remove downloads
- Downloads support queue management, completed-library browsing, sorting, and offline reader entry
- Downloaded library sorting uses local snapshots: downloaded time, last read time, and favorites count at download time
- Blocked tags are persisted in `AppOptions` as a JSON list and applied as `-tag:xxx` exclusions on every search
- All nhentai network calls use the v2 API (`/api/v2/...`); the legacy v1 endpoints are no longer used

<p align="right"><a href="#readme-top">‣ back to top</a></p>

## APIs

API notes and endpoint references live in [API-README.md](API-README.md).

<p align="right"><a href="#readme-top">‣ back to top</a></p>

## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

<p align="right"><a href="#readme-top">‣ back to top</a></p>

## Contact

Author: ttdyce - i@ttdyce.com

Project Link: [https://github.com/ttdyce/nhviewer-universal](https://github.com/ttdyce/nhviewer-universal)

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

[contributors-shield]: https://img.shields.io/github/contributors/ttdyce/nhviewer-universal.svg?style=for-the-badge
[contributors-url]: https://github.com/ttdyce/nhviewer-universal/graphs/contributors
[license-shield]: https://img.shields.io/github/license/ttdyce/nhviewer-universal.svg?style=for-the-badge
[license-url]: https://github.com/ttdyce/nhviewer-universal/blob/main/LICENSE.txt
