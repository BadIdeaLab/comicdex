# nhviewer-universal 程式架構筆記

> 對象讀者：熟悉 Java，但對 Android / Flutter / Dart 幾乎零基礎的開發者。
>
> 這份筆記說明專案的：進入點、執行流程、分層架構、各類別職責、資料儲存方式、主要演算法。
>
> **重要：本專案已從早期「單一大型 `main.dart`」重構為分層架構。** 若你看過舊版筆記（描述 `Store` / SQLite / Cloudflare WebView cookie / v1 API），那些內容已不存在，請以本文件為準。

---

## 目錄

1. [先用 Java 腦袋理解](#1-先用-java-腦袋理解)
2. [分層架構總覽](#2-分層架構總覽)
3. [目錄結構對照表](#3-目錄結構對照表)
4. [進入點與啟動流程](#4-進入點與啟動流程)
5. [路由與畫面結構](#5-路由與畫面結構)
6. [依賴注入（Provider）](#6-依賴注入provider)
7. [狀態層（state/）](#7-狀態層state)
8. [應用層（application/）](#8-應用層application)
9. [服務層（services/）](#9-服務層services)
10. [儲存層（storage/）與 Drift 資料庫](#10-儲存層storage與-drift-資料庫)
11. [資料模型（models/）](#11-資料模型models)
12. [主要資料流](#12-主要資料流)
13. [核心演算法](#13-核心演算法)
14. [Android 原生層與認證](#14-android-原生層與認證)
15. [主題系統](#15-主題系統)
16. [建議的閱讀順序](#16-建議的閱讀順序)
17. [一句話總結](#17-一句話總結)

---

## 1. 先用 Java 腦袋理解

若你熟悉 Java，可以先把概念這樣映射：

| Flutter / Dart 概念 | 可類比的 Java / Android 概念 |
| --- | --- |
| `main()` | `public static void main()` / App 啟動點 |
| `Widget` | View / Fragment / RecyclerView item 的組合 |
| `StatefulWidget` | 有內部狀態的 UI 元件（View + controller） |
| `StatelessWidget` | 純展示元件，輸入決定輸出 |
| `ChangeNotifier` | 可觀察狀態物件，類似 ViewModel + Observer |
| `Provider` | 依賴注入容器 + 狀態共享（類似精簡版 Spring DI） |
| `GoRouter` | 路由器 / 頁面導頁規則 |
| Drift `Table` / `@DriftDatabase` | JPA Entity / ORM + DAO |
| `Dio` | HTTP client（類似 OkHttp / Retrofit） |
| Use Case 類別 | Service / Interactor（單一業務動作） |
| Repository 類別 | DAO / Repository 模式 |

本專案大致可理解成五層：

1. **UI 層**：`screens/` 畫面、`widgets/` 可重用元件
2. **狀態層**：`state/` 的 `ChangeNotifier` 模型，被 UI 監聽
3. **應用層**：`application/` 的 Use Case 與 Coordinator，封裝單一業務動作
4. **服務層**：`services/` 的 API client、CDN 解析、圖片處理等無狀態服務
5. **儲存層**：`storage/` 的 Drift 資料庫與 Repository，加上 secure storage

---

## 2. 分層架構總覽

```
              ┌─────────────────────────────────────────────┐
   UI 層       │  screens/        widgets/                    │
              └───────────────┬─────────────────────────────┘
                              │ 監聽（context.watch / Consumer）
              ┌───────────────▼─────────────────────────────┐
   狀態層      │  state/   (ChangeNotifier：Feed / Reader /    │
              │           Download / Favorite / Home UI ...)  │
              └───────────────┬─────────────────────────────┘
                              │ 呼叫
              ┌───────────────▼─────────────────────────────┐
   應用層      │  application/  (Use Case + Coordinator)      │
              └──────┬────────────────────────┬─────────────┘
                     │                        │
       ┌─────────────▼──────────┐ ┌──────────▼──────────────┐
   服務層 │ services/ (API/CDN/   │ │ storage/ (Drift Repo /  │ 儲存層
       │  圖片/查詢字串建構)     │ │  secure store / options) │
       └────────────┬───────────┘ └──────────┬──────────────┘
                    │                        │
       ┌────────────▼──────┐    ┌────────────▼──────────────┐
       │ nhentai v2 API    │    │ local_database (SQLite)   │
       │ + 圖片 CDN        │    │ + flutter_secure_storage  │
       └───────────────────┘    └───────────────────────────┘
```

設計原則：

- **UI 不直接碰資料庫或 API。** 畫面只監聽狀態模型，動作透過 Coordinator / Controller 轉交給 Use Case。
- **Use Case 單一職責。** 每個 `*_use_case.dart` 只做一件事（搜尋、載入詳情、收藏切換…）。
- **Repository 隔離儲存細節。** UI / 應用層拿到的是領域模型，不是 Drift 的 row。
- **介面與實作分離。** 例如 `NhentaiGateway`（介面）↔ `NhentaiApiClient`（實作）、`RemoteAssetFetcher` ↔ `DioRemoteAssetFetcher`，方便測試替身。

---

## 3. 目錄結構對照表

| 路徑 | 角色 |
| --- | --- |
| `lib/main.dart` | 極簡進入點：初始化 DB 與 tag 字典，啟動 `BootstrapApp` |
| `lib/app/bootstrap_app.dart` | 組裝 `MultiProvider + MaterialApp.router` |
| `lib/app/app_providers.dart` | 集中宣告所有 Provider（DI 接線圖） |
| `lib/app/app_router.dart` | GoRouter 路由與底部導覽 / FAB shell |
| `lib/screens/` | 各頁面（bootstrap / home / collection / reader / settings） |
| `lib/widgets/` | 可重用 UI 元件（卡片、grid、bottom sheet、圖片載入…） |
| `lib/state/` | `ChangeNotifier` 狀態模型 |
| `lib/application/` | Use Case 與 Coordinator，依領域分子資料夾 |
| `lib/services/` | 無狀態服務：API client、CDN、圖片、查詢字串建構 |
| `lib/storage/` | Drift `LocalDatabase`、Repository、secure / options store |
| `lib/models/` | 領域資料模型與列舉（純資料，多用 freezed / json） |
| `lib/theme.dart` | Material 3 主題色與 `ThemeData` |
| `android/.../MainActivity.java` | 空殼 `FlutterActivity`（無原生業務邏輯） |
| `assets/tag_zh.bin` | 靜態 tag 中文名對照（由 `TagDisplayService` 載入） |

`lib/application/` 子資料夾依領域分類：`feed`、`home`、`library`、`reader`、`tags`、`favorites`、`downloads`、`search`。

---

## 4. 進入點與啟動流程

### `main()`（`lib/main.dart`）

職責刻意極薄：

1. `WidgetsFlutterBinding.ensureInitialized()`
2. Android 平台嘗試 `FlutterDisplayMode.setHighRefreshRate()`
3. 建立並 `initialize()` `LocalDatabase`（Drift）
4. `TagDisplayService.load()` 載入 tag 中文名對照
5. `runApp(BootstrapApp(...))`，把 DB 與 tag service 注入

### `BootstrapApp`（`lib/app/bootstrap_app.dart`）

用 `buildAppProviders(...)` 包一層 `MultiProvider`，再建立 `MaterialApp.router`，套用 `buildAppTheme()` 與 `createAppRouter()`。

### 第一個畫面：`BootstrapScreen`（`/`）

**注意：舊版的 Cloudflare WebView cookie 驗證流程已完全移除。** 現在的 `BootstrapScreen` 很單純：

1. `initState` 用 post-frame callback 觸發
2. 設定 `HomeUiModel.isLoading = true`
3. 呼叫 `ComicFeedModel.loadHomeFeed()` 載入首頁
4. 完成後關閉 loading，`context.go('/index')` 進主畫面

啟動流程：

```
main()
  └─ LocalDatabase.initialize()      // Drift 開檔 + migration
  └─ TagDisplayService.load()        // 載入 assets/tag_zh.bin
  └─ runApp(BootstrapApp)
       └─ MultiProvider              // DI 接線
       └─ GoRouter → '/'
            └─ BootstrapScreen
                 └─ ComicFeedModel.loadHomeFeed()
                 └─ go('/index') → HomeShell
```

---

## 5. 路由與畫面結構

路由由 `createAppRouter()`（`app_router.dart`）建立：

| 路由 | 畫面 | 功能 |
| --- | --- | --- |
| `/` | `BootstrapScreen` | 載入首頁後跳轉 |
| `/index` | `HomeShell` | 首頁 / Downloads / Collections 三頁籤主畫面 |
| `/collection?collectionName=` | `CollectionScreen` | 單一收藏夾內容 |
| `/third?id=` | `ComicReaderScreen` | 單本漫畫閱讀頁 |
| `/settings` | `SettingsScreen` | 設定頁 |

`/index` 與 `/collection` 被包在一個 `ShellRoute`（`_AppShellScaffold`）內，提供：

- 底部 `NavigationBar`（Home / Downloads / Collections）
- 依目前頁籤切換的 `FloatingActionButton`：
  - index 0（Home）→ `_SortFilterFab`（排序 + tag 篩選，有條件時顯示 badge）
  - index 1（Downloads）→ `_DownloadsSortFab`（下載排序）
- 切頁時透過 `AppShellNavigationController` 處理並 `goNamed('index')`

底部三個頁籤的內容由 `HomeShell` 依 `HomeUiModel.navigationIndex` 切換，而非各自獨立路由。

---

## 6. 依賴注入（Provider）

所有相依物件集中在 `app_providers.dart` 的 `buildAppProviders()`，回傳一份 `List<SingleChildWidget>`。這就是整個專案的「接線圖」，閱讀它能一眼看出物件依賴關係。

注入順序（由底層往上）：

1. **基礎設施**：`TagDisplayService`、`LocalDatabase`、`OptionsStore`、`SecureKeyValueStore`
2. **儲存 Repository**：`ComicRepository`、`CollectionRepository`、`SearchHistoryRepository`、`DownloadQueueRepository`、`DownloadedLibraryRepository`，以及各 settings / blocked-tags / reader store
3. **服務**：`SearchQueryBuilder`、`TagSearchQueryBuilder`、`ComicPageSourceResolver`、`DownloadAssetStore`、`ImageCompressionService`、`RemoteAssetFetcher`、`NhentaiCdnConfigService`、`ImageUrlResolver`、`NhentaiAuthService`、`NhentaiApiClient`(`NhentaiGateway`)、`RemoteFavoriteGateway`
4. **Use Case**：搜尋、收藏、library、reader、tags 等各動作
5. **狀態模型**（`ChangeNotifierProvider`）：`HomeUiModel`、`BlockedTagsModel`、`TagCatalogBrowserModel`、`ComicFeedModel`、`FavoriteSyncModel`、`DownloadManagerModel`、`ComicReaderModel`
6. **Coordinator / Controller**：`AppShellNavigationController`、`HomeShellController`、`CollectionPageCoordinator`、`ComicCardActionCoordinator`

部分狀態模型在 `create` 時就呼叫 `load()` / `initialize()`（如 `BlockedTagsModel`、`FavoriteSyncModel`、`DownloadManagerModel`），完成自我初始化。

---

## 7. 狀態層（state/）

`state/` 的每個類別都是 `ChangeNotifier`，被 UI 監聽。它們持有 UI 狀態並委派業務動作給 Use Case。

| 模型 | 職責 |
| --- | --- |
| `HomeUiModel` | 底部導覽 index、`SearchController`、全域 loading；切頁時清空搜尋欄 |
| `ComicFeedModel` | 首頁 / 搜尋的漫畫列表、分頁、排序、語言、tag 篩選、封鎖 tag 套用 |
| `ComicReaderModel` | 當前漫畫、頁碼導覽、`PageController`、預抓頁數、閱讀方向、點擊區比例、控制列顯示 |
| `DownloadManagerModel` | 下載佇列引擎（排程 / 暫停 / 續傳 / 重下 / 修復）、完成清單、排序；監聽 app 生命週期 |
| `FavoriteSyncModel` | 收藏 id 集合、API key 認證狀態、與遠端收藏同步、樂觀切換收藏 |
| `BlockedTagsModel` | 封鎖 tag 清單的載入 / 新增 / 移除 |
| `TagCatalogBrowserModel` | tag 目錄瀏覽（類型切換、分頁、多選 query） |

設計重點：

- 模型本身**不**直接發 API / 寫 DB，而是呼叫注入進來的 Use Case 與 Repository。
- 多數模型用「請求序號」或「mutating id 集合」避免併發競態（如 `TagCatalogBrowserModel._requestSequence`、`FavoriteSyncModel._mutatingIds`）。

---

## 8. 應用層（application/）

應用層把「一個業務動作」封裝成一個類別，分兩種：

**Use Case（單一動作）** — 例如：

| Use Case | 功能 |
| --- | --- |
| `SearchComicsUseCase` | 用查詢字串建構 URI 並向 gateway 取列表 |
| `LoadCollectionSummariesUseCase` | 載入各收藏夾摘要 |
| `LoadCollectionComicsUseCase` | 載入單一收藏夾的漫畫 |
| `LoadComicDetailUseCase` | 載入單本漫畫詳情（含 headers） |
| `LoadOfflineComicUseCase` | 從本地下載資產組出可離線閱讀的漫畫 |
| `OpenComicUseCase` | 開啟漫畫時寫入 `Comic` 與 `History` |
| `LoadComicMetaUseCase` | 載入 tag / 詳情 meta |
| `SaveComicToCollectionUseCase` / `RemoveComicFromCollectionUseCase` | 收藏夾加入 / 移除 |
| 收藏類：`InitializeFavoritesUseCase`、`SaveApiKeyUseCase`、`ClearFavoriteAuthUseCase`、`SyncRemoteFavoritesUseCase`、`ToggleFavoriteUseCase` | 收藏的初始化、API key、與遠端同步、切換 |

**Coordinator / Controller（編排多個 Use Case + 狀態）** — 例如：

| 類別 | 功能 |
| --- | --- |
| `HomeShellController` | 首頁互動編排：送出搜尋、tag 搜尋、重試、套用排序 / 篩選 |
| `AppShellNavigationController` | 處理底部導覽切換的副作用 |
| `CollectionPageCoordinator` | 收藏頁載入與快照協調 |
| `ComicCardActionCoordinator` | 漫畫卡片動作：開啟、載入 meta、收藏、移除、切換收藏、加入下載 |

此外 `application/` 也放部分 Repository 介面（`ReaderProgressRepository`、`ReaderSettingsRepository`、`DownloadSettingsRepository`、`BlockedTagsRepository`），實作則在 `storage/`，達成依賴反轉。

---

## 9. 服務層（services/）

無狀態（或僅持快取）的服務：

| 服務 | 功能 |
| --- | --- |
| `NhentaiApiClient`（`NhentaiGateway`） | nhentai **v2 API** 的唯一進出口：列表 / 搜尋 / 詳情 / meta / tag 目錄 |
| `NhentaiCdnConfigService` | 啟動時 ping CDN 設定端點，解析目前可用圖片主機 |
| `ImageUrlResolver` | 依 CDN 設定組出縮圖 / 內頁圖片 URL |
| `ComicPageSourceResolver` | 解析單頁圖片來源 URL |
| `NhentaiAuthService` | API key 載入 / 驗證 / 清除（搭配 secure store） |
| `RemoteFavoriteGateway`（`NhentaiApiRemoteFavoriteGateway`） | 遠端收藏的讀取 / 新增 / 移除（需認證） |
| `RemoteAssetFetcher`（`DioRemoteAssetFetcher`） | 下載原始位元組 |
| `ImageCompressionService`（`FlutterImageCompressionService`） | 將下載頁壓成 webp |
| `DownloadAssetStore` | 下載檔案在磁碟上的存放 / 驗證 / 刪除（與圖片快取分離） |
| `SearchQueryBuilder` / `TagSearchQueryBuilder` | 組搜尋 URI、把多個 tag query 串成搜尋字串 |
| `TagDisplayService` | 從 `assets/tag_zh.bin` 提供 tag slug → 中文顯示名 |
| `LibraryImportService` | 從外部來源匯入收藏 / 漫畫 |

多數服務以「抽象介面 + 具體實作」成對出現，便於單元測試替身。

---

## 10. 儲存層（storage/）與 Drift 資料庫

本地持久化已從 sqflite 遷移到 **Drift**（見 phase P5）。核心是 `LocalDatabase`（`local_database.dart`），目前 `schemaVersion = 9`，migration 以 `onUpgrade` 逐版本撰寫。

### 資料表

| Table 類別 | 實體名 | 用途 |
| --- | --- | --- |
| `AppOptions` | `Options` | key-value 設定（reader / download 設定、封鎖 tag JSON、閱讀進度等） |
| `Comics` | `Comic` | 漫畫基本資料（id / mid / title / images / pages） |
| `Collections` | `Collection` | 收藏關係（name + comicid 主鍵），含 `favorite_rank` 保留遠端收藏排序 |
| `SearchHistories` | `SearchHistory` | 搜尋歷史 |
| `DownloadJobs` | `DownloadJob` | 下載任務（狀態、進度、next page、重試…） |
| `DownloadJobPages` | `DownloadJobPage` | 每頁下載狀態（本地路徑、格式、位元組數…） |
| `DownloadedComics` | `DownloadedComic` | 已完成下載漫畫的快照（標題、封面、頁數、最後閱讀、收藏數快照、tags JSON） |

`Collection` 可存的 `name` 包含 `Favorite` / `Next` / `History`。

### Repository

每個 Repository 封裝一組相關資料表的存取，回傳領域模型而非 Drift row：

- `ComicRepository`、`CollectionRepository`、`SearchHistoryRepository`
- `DownloadQueueRepository`（`DownloadJobs` + `DownloadJobPages`）
- `DownloadedLibraryRepository`（`DownloadedComics`）
- `OptionsStore`（key-value 基礎），其上再包：`ReaderProgressStore`、`ReaderSettingsStore`、`DownloadSettingsStore`、`BlockedTagsStore`
- `NhentaiApiKeyStore` ← `SecureKeyValueStore`（`flutter_secure_storage`）儲存 API key

下載檔案存放在獨立目錄（透過 `DownloadAssetStore`），與 `cached_network_image` 的圖片快取分離，因此清快取不會刪掉已下載內容。

---

## 11. 資料模型（models/）

`models/` 是純資料層，多數用 freezed / json_serializable 產生（對應 `*.freezed.dart` / `*.g.dart`）。主要分三類：

**領域模型**

| 類別 | 功能 |
| --- | --- |
| `Comic` | 單本漫畫領域模型 |
| `ComicTitle` / `ComicImages` / `ComicPageImage` / `ComicTag` | 漫畫的標題 / 圖片 / 單頁 / 標籤 |
| `ComicSearchResponse` | 列表 / 搜尋 API 回應 |
| `ComicCardData` | 卡片顯示用的精簡資料 |
| `CollectionSummary` / `CollectedComic` / `StoredComic` | 收藏摘要與已存漫畫 |
| `LocalTagCatalogEntry` | 本地標籤資料集項目（type/name/slug/count，P58） |
| `NhentaiCdnConfig` / `NhentaiApiCredential` | CDN 設定、API 認證 |

**下載相關快照**

`DownloadJobSnapshot`、`DownloadPageSnapshot`、`DownloadListItemSnapshot`、`DownloadedComicSnapshot`、`DownloadRequest`，以及狀態列舉 `DownloadJobStatus`、`DownloadPageStatus`、`DownloadsSortMode`。

**列舉**

`ComicLanguage`、`PopularSortType`、`ImageFormat`、`CollectionType`、`TagCatalogType`、`SearchHistoryEntry`、`TagTypeL10n`。

---

## 12. 主要資料流

### 首頁載入

```
BootstrapScreen
  → ComicFeedModel.loadHomeFeed()
  → SearchComicsUseCase.execute()
      → SearchQueryBuilder.buildSearchUri()
      → NhentaiGateway.searchComics(uri)        // v2 /api/v2/galleries|search
  → ComicSearchResponse → List<Comic>
  → 套用封鎖 tag → 存入 ComicFeedModel
  → notifyListeners() → HomeShell 的 ComicGridSliver 顯示
```

### 點開漫畫

```
ComicCard.onTap
  → ComicCardActionCoordinator.openComic()
  → ComicReaderModel + LoadComicDetailUseCase
      → NhentaiGateway.loadComicDetail(id)      // v2 /api/v2/galleries/<id>
  → OpenComicUseCase：寫入 Comic + History
  → ComicReaderScreen 逐頁顯示
```

### 收藏（含遠端同步）

```
ComicCard 收藏鈕
  → ComicCardActionCoordinator.toggleFavorite()
  → ToggleFavoriteUseCase
      → CollectionRepository（本地）
      → RemoteFavoriteGateway（遠端，需 API key）
      → SyncRemoteFavoritesUseCase（保留 favorite_rank 排序）
  → FavoriteSyncModel 樂觀更新 → UI
```

### 下載

```
ComicCard 長壓 → 下載
  → ComicCardActionCoordinator.enqueueDownload()
  → DownloadManagerModel
      → DownloadQueueRepository（建立 DownloadJob + Pages）
      → 逐頁 RemoteAssetFetcher 抓 → ImageCompressionService 壓 webp
      → DownloadAssetStore 存檔
      → 完成後寫入 DownloadedComics 快照
  → Downloads 頁籤顯示進度 / 完成卡片
```

### 離線閱讀

```
已完成下載卡片 → 開啟
  → LoadOfflineComicUseCase（讀 DownloadQueueRepository + DownloadedLibraryRepository）
  → 用本地頁面檔案組出 Comic（不發網路）
  → ComicReaderScreen 顯示
```

---

## 13. 核心演算法

### 13.1 搜尋查詢字串建構

`SearchQueryBuilder` / `TagSearchQueryBuilder` 把使用者輸入、語言篩選、tag 篩選與封鎖 tag（前綴 `-`）組成最終 v2 query。語言可能有 fallback 字串（見 `API-README.md`）。

### 13.2 Infinite scroll

`ComicGridSliver` 在繪製接近最後一筆時，若 `!noMorePage` 且未在 loading，觸發 `ComicFeedModel` 抓下一頁（`pageLoaded + 1`）。

### 13.3 封鎖 tag 套用

每次搜尋時，`ComicFeedModel` 從 `BlockedTagsRepository` 取出封鎖清單，於 query 末端附加 `-<tag>` 排除。封鎖 tag 以 JSON 陣列存在 `AppOptions`。

### 13.4 圖片多重 fallback

`FallbackCachedNetworkImage` 透過 `ImageUrlResolver` / `ComicPageSourceResolver` 生成多組候選 URL：在多個子網域（`i1`–`i4` / `t1`–`t4`）與多種副檔名（jpg / webp / png / gif）之間逐一重試，以對應 nhentai 圖片實際主機與格式不一致的問題。

### 13.5 下載引擎狀態機

`DownloadManagerModel` 維護任務狀態（queued / downloading / paused / failed / completed），逐頁推進 `next_page_number`，並依 `DownloadSettings`（auto-resume、頁間隔）控制節奏。它 `with WidgetsBindingObserver`，在 app 生命週期變化時調整續傳行為（auto-resume 關閉時把中斷任務轉為 paused）。重下（Reload）與修復（Repair）分別重抓全部與補缺頁。

### 13.6 閱讀進度保存

`ComicReaderModel` 透過 `ReaderProgressRepository`（底層 `OptionsStore`）保存每本漫畫的最後頁碼 / 位移，下次進入同一本時捲回。

### 13.7 收藏排序保留

遠端收藏同步時，`Collection.favorite_rank` 記錄遠端收藏順序（0 = 最近收藏），使本地收藏頁能依遠端排序顯示（phase P28）。

---

## 14. Android 原生層與認證

**舊版的 WebView cookie / `MethodChannel` cookie 橋接已完全移除。** 現在 `MainActivity.java` 只是空殼：

```java
public class MainActivity extends FlutterActivity {}
```

認證改用 **nhentai v2 API key**：

- 使用者在設定頁輸入 API key
- `NhentaiAuthService` 驗證並透過 `NhentaiApiKeyStore` → `flutter_secure_storage` 安全保存
- 需認證的請求（收藏同步等）以 `Authorization: Key <api_key>` 標頭送出

Android build 設定仍在 `android/settings.gradle.kts`（plugin / Kotlin 版本）與 `android/app/build.gradle.kts`（namespace、SDK、Java / Kotlin target）。

---

## 15. 主題系統

在 `lib/theme.dart`：

- `NHVMaterialTheme` 提供 light / dark / contrast 多組 Material 3 色票
- `MaterialScheme` 是純資料結構，描述一整組顏色
- `MaterialSchemeUtils.toColorScheme()` 把自訂 scheme 轉成 Flutter `ColorScheme`
- `buildAppTheme()` 組裝最終 `ThemeData`，供 `BootstrapApp` 使用

---

## 16. 建議的閱讀順序

1. `lib/main.dart` → `lib/app/bootstrap_app.dart`
2. `lib/app/app_providers.dart`（接線圖，看依賴關係）
3. `lib/app/app_router.dart`（路由與 shell）
4. `lib/screens/home_shell.dart` + `lib/widgets/comic_grid_sliver.dart`、`comic_card.dart`
5. `lib/state/comic_feed_model.dart` → `lib/application/feed/`
6. `lib/state/comic_reader_model.dart` → `lib/screens/comic_reader_screen.dart`
7. `lib/state/download_manager_model.dart` → `lib/storage/download_queue_repository.dart`
8. `lib/storage/local_database.dart`（資料表與 migration）
9. `lib/services/nhentai_api_client.dart`（v2 API 進出口）

---

## 17. 一句話總結

這是一個用 Flutter 寫的 nhentai 閱讀器，採分層架構：UI（screens/widgets）監聽 `ChangeNotifier` 狀態層，狀態層委派給應用層 Use Case / Coordinator，再由服務層（v2 API / CDN / 圖片）與儲存層（Drift / secure storage）完成工作。核心功能涵蓋首頁搜尋與封鎖 tag、收藏與遠端同步、可續傳下載與離線閱讀、以及 tag 中文名顯示。
