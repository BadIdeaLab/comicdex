# 測試指南

本目錄的測試除了驗證功能正確性，也作為新成員理解專案分層、資料流與行為規則的入口。建議先閱讀本文件，再依照下方的建議順序瀏覽測試檔。

## 目的

- 驗證核心資料模型、應用流程、狀態管理與本地儲存邏輯。
- 讓新成員可以透過測試快速理解各模組的責任邊界。
- 在重構時提供回歸保護，避免行為規則被無意改壞。

## 目錄分層

- `test/models/`
  - 驗證資料模型、enum、值規則與 mapper 行為。
- `test/application/`
  - 驗證 use case、流程協調與業務規則。
- `test/services/`
  - 驗證 API client、resolver、import service 等整合邏輯。
- `test/state/`
  - 驗證 `ChangeNotifier` 與 UI-facing state contract。
- `test/storage/`
  - 驗證本地 repository、SQLite 行為與資料查詢規則。
- `test/widgets/`
  - 驗證單一 widget 或單一畫面區塊的顯示與互動。
- `test/test_support/`
  - 放置 fixture、fake、network stub 與 SQLite 測試工具。

## 建議閱讀順序

如果你是第一次接觸這個專案，建議依照下面順序閱讀：

1. `test/models/`
2. `test/storage/`
3. `test/application/`
4. `test/state/`
5. `test/services/`
6. `test/widgets/`

這個順序會先建立資料結構與本地儲存的理解，再往上讀應用流程、狀態管理與 UI 行為。

## 如何開始測試

1. 安裝相依套件：

```bash
flutter pub get
```

2. 執行全部測試：

```bash
flutter test
```

3. 執行單一測試檔：

```bash
flutter test test/services/nhentai_api_client_test.dart
```

4. 執行特定分類資料夾：

```bash
flutter test test/application
flutter test test/storage
```

5. 執行靜態分析：

```bash
flutter analyze
```

## 執行環境需求

- 需要已安裝 Flutter SDK，版本請以專案根目錄目前使用的 Flutter 設定為準。
- 需要可用的 `flutter` 與 `dart` CLI。
- 多數測試為 pure Dart test 或 widget test，不需要 Android Emulator 或 iOS Simulator。
- 本地儲存測試使用 in-memory SQLite，因此 Windows、macOS、Linux 都可以執行。
- `flutter test --coverage` 可作為選用步驟，但目前不列為必跑項目；若環境較慢，可能會比一般測試更容易超時。

## 常用指令

執行全部測試：

```bash
flutter test
```

只跑某一層測試：

```bash
flutter test test/models
flutter test test/services
flutter test test/state
```

只跑單一案例檔案：

```bash
flutter test test/state/home_ui_model_test.dart
```

搭配分析一起檢查：

```bash
flutter analyze
flutter test
```

## 如何新增新測試

新增測試時請遵守以下原則：

- 依責任放入正確資料夾，不要把多個層次的規則混在同一個檔案。
- 檔名使用 `<subject>_test.dart`。
- 每個測試檔應聚焦單一主題，例如一個 repository、一個 use case 或一個 state model。
- 優先重用 `test/test_support/` 內的 fixture、fake 與 SQLite harness，避免重複建立測試樣板。
- 如果是應用流程測試，至少要覆蓋成功路徑與失敗路徑。

## 常見失敗原因與排查方向

- `flutter pub get` 尚未執行或套件版本未同步。
- 新增測試時使用了錯誤的分層，導致測試依賴過多實作細節。
- SQLite 測試沒有正確清理 in-memory database，導致前一個案例資料殘留。
- network stub 回傳資料格式與 production mapping 不一致，造成 JSON 解析失敗。
- widget test 中忘記建立必要的 `MaterialApp`、`Scaffold` 或其他基本上下文。

## 給新成員的建議

- 想理解資料長什麼樣子，先看 `test/models/`。
- 想理解收藏、閱讀器、搜尋這些功能怎麼串起來，先看 `test/application/` 與 `test/state/`。
- 想理解本地資料如何保存與查詢，先看 `test/storage/`。
- 想理解 API 與外部整合邏輯，先看 `test/services/`。
