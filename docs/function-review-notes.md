# nhviewer-universal 函式整理、分類與擴充建議

> 本文件依現狀分層架構，逐層整理重要類別與函式：在做什麼、屬於哪一類、未來擴充時怎麼改。
>
> **重要更新：** 早期版本（描述 `main.dart` 單檔承載、`Store` 類別、`FirstScreen` Cloudflare cookie 流程）所列的多數重構建議，**已在後續 phase 完成**。本文件改以「現狀」為基準，並在最後列出仍值得改善的點。請搭配 [`architecture-notes.md`](./architecture-notes.md) 一起閱讀。

---

## 目錄

1. [函式分類方式](#1-函式分類方式)
2. [App 啟動與骨架](#2-app-啟動與骨架)
3. [路由與導覽](#3-路由與導覽)
4. [畫面（screens/）](#4-畫面screens)
5. [可重用元件（widgets/）](#5-可重用元件widgets)
6. [狀態層（state/）](#6-狀態層state)
7. [應用層（application/）](#7-應用層application)
8. [服務層（services/）](#8-服務層services)
9. [儲存層（storage/）](#9-儲存層storage)
10. [歷史重構對照（已完成）](#10-歷史重構對照已完成)
11. [仍值得改善的點](#11-仍值得改善的點)
12. [一句話總結](#12-一句話總結)

---

## 1. 函式分類方式

現狀的函式可分成 9 類：

1. 啟動 / bootstrap
2. 路由 / 導覽
3. 畫面組裝（screen build）
4. 可重用 UI 元件
5. 狀態管理（`ChangeNotifier`）
6. 應用層動作（Use Case / Coordinator）
7. 遠端服務（API / CDN / 認證 / 圖片）
8. 本地儲存（Drift Repository / secure / options）
9. 資料模型 / 主題

與舊版最大的差異：**「本地資料存取」不再集中在單一 `Store`，而是分散到多個 Repository；「啟動 / cookie 驗證」也不再混在 `FirstScreen`。** 責任已明確分層。

---

## 2. App 啟動與骨架

| 函式 / 類別 | 功能 | 分類 | 擴充建議 |
| --- | --- | --- | --- |
| `main()`（`main.dart`） | 初始化 binding、高更新率、`LocalDatabase`、`TagDisplayService`，啟動 `BootstrapApp` | bootstrap | 已很精簡；新增啟動步驟時保持「只做初始化、不放 UI」 |
| `BootstrapApp.build()` | 組裝 `MultiProvider + MaterialApp.router` | bootstrap | 主題 / router 已外抽，維持薄殼 |
| `buildAppProviders()`（`app_providers.dart`） | 集中宣告所有 Provider | DI | 新依賴一律加在此處；可考慮依領域拆成多個 `build*Providers()` 以縮短檔案 |
| `buildAppTheme()`（`theme.dart`） | 建立 `ThemeData` | 主題 | 若要支援使用者切換 light/dark，改成接收參數 |
| `BootstrapScreen._loadHomeFeedAndNavigate()` | 載入首頁後跳 `/index` | bootstrap / 畫面流程 | 流程已簡單；若要加啟動檢查（版本 / 公告）在此擴充 |

---

## 3. 路由與導覽

| 函式 / 類別 | 功能 | 分類 | 擴充建議 |
| --- | --- | --- | --- |
| `createAppRouter()`（`app_router.dart`） | 定義 GoRouter 路由與 shell | 路由 | 新頁面在此註冊；query 參數解析集中於 builder |
| `_AppShellScaffold` | 底部 `NavigationBar` + 依頁籤切換的 FAB | 導覽外框 | 頁籤增加時擴充 `destinations` 與 FAB 的 `switch` |
| `_SortFilterFab` / `_DownloadsSortFab` | 各頁籤對應的排序 / 篩選 FAB（有條件顯示 badge） | 導覽 | 新增頁籤專屬動作時新增對應 FAB 類別 |
| `AppShellNavigationController.handleDestinationSelected()` | 處理切頁副作用並回傳狀態訊息 | 應用層 / 導覽 | 切頁邏輯集中於此，UI 只負責顯示結果 |

---

## 4. 畫面（screens/）

| 類別 | 功能 | 命名 | 擴充建議 |
| --- | --- | --- | --- |
| `BootstrapScreen` | 啟動載入頁 | 佳（已取代舊 `FirstScreen`） | — |
| `HomeShell` | 首頁主畫面：搜尋列、loading、依頁籤切內容 | 佳 | build 已偏大，可再抽各頁籤內容為獨立 widget |
| `CollectionOverviewScreen`（於 `home_shell.dart`） | 收藏總覽（History / Next / Favorite 入口） | 佳（已取代舊 `CollectionListScreen`） | 若收藏類型增加，改以資料驅動產生入口 |
| `CollectionScreen` + `CollectionComicSliver` | 單一收藏夾內容 | 佳（已取代舊 `CollectionSliver`） | Map→view 轉換可移到 mapper |
| `ComicReaderScreen` | 閱讀頁（取代舊 `ThirdScreen`） | 佳 | 內含 `_PageWidget`、`_AnimatedTopBar`、`_AnimatedBottomControls`、`_EndCard`、`_ReaderSettingsSheet`，職責切分清楚 |
| `SettingsScreen` | 設定頁（語言、reader、download、API key、封鎖 tag…） | 佳 | 設定項增加時，將每組設定抽成 section widget |

---

## 5. 可重用元件（widgets/）

| 類別 | 功能 | 擴充建議 |
| --- | --- | --- |
| `ComicCard` | 單本漫畫卡片（點擊閱讀、收藏、下載、長壓選單） | 動作已委派給 `ComicCardActionCoordinator`，維持 UI 純粹 |
| `ComicGridSliver` | 漫畫 grid + infinite scroll 觸發 | 抓下一頁邏輯透過 `ComicFeedModel`，不在 widget 內發 API |
| `CollectionGridSliver` | 收藏入口 grid | 以資料驅動，避免硬編 childCount |
| `FallbackCachedNetworkImage` | 圖片載入 + 子網域 / 副檔名 fallback | URL 候選產生建議補單元測試 |
| `ComicTagBottomSheet` + `_TagTypeSection` | tag 檢視 / 多選 / 封鎖；套用中文名 | tag 類型分組 |
| `DownloadJobListSliver`（含 `_DownloadItemCard` 等） | 下載清單（進行中 + 完成卡片） | 卡片已細分為 active / completed summary |
| `DownloadsSortBottomSheet` / `SortFilterBottomSheet` / `_SortChip` | 排序與篩選面板 | — |
| `SearchSuggestionsPanel` | 搜尋建議（含鍵盤 UX 處理） | — |
| `LoadingIndicatorBar` | 全域 loading 線條 | — |

---

## 6. 狀態層（state/）

所有皆為 `ChangeNotifier`。函式以 setter / 動作為主，業務交給注入的 Use Case。

| 模型 | 代表性函式 | 擴充建議 |
| --- | --- | --- |
| `HomeUiModel` | `setNavigationIndex()`、`setLoading()`、`closeSearchView()`、`resetSearchView()` | 切頁清搜尋欄邏輯集中於此 |
| `ComicFeedModel` | `loadHomeFeed()`、`search*`、分頁、`toggleSort()` / `setSortType()`、`setLanguage()`、tag 篩選 | 抓頁與封鎖 tag 套用已委派 Use Case / Repository |
| `ComicReaderModel` | 頁碼導覽、`loadSettings()`、預抓 / 閱讀方向 / 點擊區設定、控制列顯示 | 設定持久化走 `ReaderSettingsRepository` |
| `DownloadManagerModel` | 下載引擎（排程 / 暫停 / 續傳 / 重下 / 修復）、排序、生命週期觀察 | 體量最大；新增下載行為時留意併發保護（`_mutatingComicIds`） |
| `FavoriteSyncModel` | `initialize()`、`syncFavorites()`、樂觀切換收藏 | 用 `_mutatingIds` 避免重複請求 |
| `BlockedTagsModel` | `load()` / `addTag()` / `removeTag()` / `isBlocked()` | — |
| `TagCatalogBrowserModel` | `ensureLoaded()` / `setType()` / `loadPage()`、多選 query | 用 `_requestSequence` 防競態 |

---

## 7. 應用層（application/）

每個 Use Case 封裝單一動作；Coordinator / Controller 編排多個 Use Case 與狀態。

| 類別 | 功能 | 分類 |
| --- | --- | --- |
| `SearchComicsUseCase` | 建 URI → gateway 取列表 | feed |
| `LoadCollectionSummariesUseCase` / `LoadCollectionComicsUseCase` | 收藏摘要 / 內容 | feed / library |
| `LoadComicDetailUseCase` / `LoadOfflineComicUseCase` / `OpenComicUseCase` | 詳情 / 離線 / 開啟並寫 History | reader |
| `LoadComicMetaUseCase` / `LoadTagCatalogUseCase` | meta / tag 目錄 | tags |
| `SaveComicToCollectionUseCase` / `RemoveComicFromCollectionUseCase` | 收藏夾加入 / 移除 | library |
| `InitializeFavoritesUseCase` / `SaveApiKeyUseCase` / `ClearFavoriteAuthUseCase` / `SyncRemoteFavoritesUseCase` / `ToggleFavoriteUseCase` | 收藏初始化 / API key / 遠端同步 / 切換 | favorites |
| `HomeShellController` | `submitSearch()` / `searchWithTag()` / `submitTagSearch()` / `retryHomeFeed()` / `applySortAndFilters()` | home 編排 |
| `AppShellNavigationController` | 切頁副作用 | home 編排 |
| `CollectionPageCoordinator` | 收藏頁載入 / 快照協調 | library 編排 |
| `ComicCardActionCoordinator` | `openComic()` / `loadComicMeta()` / `saveToCollection()` / `enqueueDownload()` / `removeFromCollection()` / `toggleFavorite()` | library 編排 |

> 應用層同時持有部分 Repository 介面（`ReaderProgressRepository`、`ReaderSettingsRepository`、`DownloadSettingsRepository`、`BlockedTagsRepository`），實作在 `storage/`，達成依賴反轉。

---

## 8. 服務層（services/）

| 類別 | 代表性函式 | 擴充建議 |
| --- | --- | --- |
| `NhentaiApiClient`（`NhentaiGateway`） | `searchComics()` / `loadComicDetail()` / `loadComicMeta()` / `loadTagCatalog()` / `pingHomepage()` | 全部走 **v2** 端點；新增端點時擴充介面 |
| `NhentaiCdnConfigService` | `load()` / `refreshInBackground()` | 啟動背景刷新，解析圖片主機 |
| `ImageUrlResolver` / `ComicPageSourceResolver` | 組縮圖 / 內頁 URL | 與 fallback 影像元件搭配 |
| `NhentaiAuthService` | `saveAndValidateApiKey()` / `validateStoredApiKey()` / `clearApiKey()` | API key 驗證 |
| `NhentaiApiRemoteFavoriteGateway`（`RemoteFavoriteGateway`） | `loadRemoteFavorites()` / `addRemoteFavorite()` / `removeRemoteFavorite()` | 需認證 |
| `DioRemoteAssetFetcher`（`RemoteAssetFetcher`） | `fetchBytes()` | 下載位元組 |
| `FlutterImageCompressionService`（`ImageCompressionService`） | `compressToWebp()` | 下載頁壓縮 |
| `DownloadAssetStore` | `savePage()` / `saveCover()` / `verifyPages()` / `deleteComicAssets()` | 下載檔案磁碟管理（與快取分離） |
| `SearchQueryBuilder` / `TagSearchQueryBuilder` | `buildSearchUri()` / `build()` | 查詢字串建構（含封鎖 tag / 語言 fallback） |
| `TagDisplayService` | `load()` / `displayName()` | tag 中文名（`assets/tag_zh.bin`） |
| `LibraryImportService` | `importFromBaseUrl()` | 匯入 |

多數服務以「抽象介面 + 具體實作」成對，便於測試替身。

---

## 9. 儲存層（storage/）

舊版的單一 `Store` 已拆成多個 Repository（phase P5 遷移到 Drift）。

| 類別 | 功能 |
| --- | --- |
| `LocalDatabase`（`@DriftDatabase`, schemaVersion 9） | 開檔、建表、逐版本 migration |
| `ComicRepository` | `Comic` 表存取 |
| `CollectionRepository` | `Collection` 表（含 `favorite_rank`） |
| `SearchHistoryRepository` | `SearchHistory` 表 |
| `DownloadQueueRepository` | `DownloadJob` + `DownloadJobPage` |
| `DownloadedLibraryRepository` | `DownloadedComic` 快照 |
| `OptionsStore` | key-value 基礎存取 |
| `ReaderProgressStore` / `ReaderSettingsStore` / `DownloadSettingsStore` / `BlockedTagsStore` | 各 typed 設定（皆建在 `OptionsStore` 上，實作對應介面） |
| `NhentaiApiKeyStore` ← `SecureKeyValueStore`（`FlutterSecureKeyValueStore`） | API key 安全存放 |

舊 `Store` 的問題（schema / CRUD / cookie / comic / collection 全混在一起）已不存在；cookie 相關 API 隨 Cloudflare 流程一併移除。

---

## 10. 歷史重構對照（已完成）

舊版本文件列出的重構建議，目前狀態：

| 舊建議 | 現狀 |
| --- | --- |
| 把 `main.dart` 拆成 screens / widgets / services / storage | ✅ 已分層 |
| 把 `Store` 抽成獨立檔案並分層 | ✅ 拆成多個 Repository + `OptionsStore` |
| 把 Cloudflare / cookie 流程抽成 service | ✅ 整個流程已移除（改用 API key 認證） |
| 把圖片 fallback 抽成獨立元件 | ✅ `FallbackCachedNetworkImage` + resolver |
| `bootstrapApp()` 化、router / provider 外抽 | ✅ `BootstrapApp` + `app_router` + `app_providers` |
| 改名 `FirstScreen` / `ThirdScreen` / `App` | ✅ → `BootstrapScreen` / `ComicReaderScreen` / `HomeShell` |
| `NHPopularType` 常數改 enum | ✅ `PopularSortType` |
| 語言 fallback 政策抽出 | ✅ 進 query builder（見 `API-README.md`） |
| sqflite → Drift | ✅ phase P5 |

---

## 11. 仍值得改善的點

1. **`app_providers.dart` 偏長**：可依領域拆成 `buildStorageProviders()` / `buildServiceProviders()` / `buildStateProviders()` 等，組合後回傳。
2. **`DownloadManagerModel` 體量大**：下載引擎邏輯（排程 / 重試 / 壓縮 / 存檔）可考慮抽出 `DownloadEngine` 服務，讓狀態模型更薄。
3. **`HomeShell` 與 `ComicReaderScreen` 的 build 仍偏大**：各頁籤 / 各 overlay 可再抽為獨立 widget。
4. **測試覆蓋**：`FallbackCachedNetworkImage` 的 URL 候選產生、`SearchQueryBuilder` / `TagSearchQueryBuilder` 的邊界情況，建議補單元測試。
5. **Collection 型別**：收藏夾名稱仍以字串流通（`Favorite` / `Next` / `History`），可評估全面改用 `CollectionType` enum 收斂 magic string。

---

## 12. 一句話總結

專案已從「單檔承載、責任集中」演進為清楚的分層架構：命名反映業務語意、儲存分散為 Repository、啟動與認證流程簡化。現階段函式大多職責單一、命名得當；後續維護重點不再是「拆大檔」，而是讓最大的狀態模型（下載）與最大的畫面（首頁 / 閱讀）持續瘦身，並補強核心邏輯的單元測試。
