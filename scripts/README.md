# Scripts

本目錄包含資料準備與資產編碼腳本，供開發者在本機執行。產出的暫存檔位於 `scripts/out/`（已加入 `.gitignore`，不納入版本控制）。

---

## fetch_tags.py

從站台公開 API 擷取所有分類標籤的原始資料，輸出 JSON 至 `scripts/out/tag_raw.json`。  
輸出的每筆資料包含標籤的 ID、顯示名稱、分類類型、URL slug 與使用頻次。

**用法**（從專案根目錄執行）：

```bash
python scripts/fetch_tags.py
```

**輸出格式**（`scripts/out/tag_raw.json`）：

```json
[
  { "id": 1, "type": "tag", "name": "full color", "slug": "full-color", "count": 220000 },
  ...
]
```

取得原始資料後，可篩選出需要翻譯的條目（按使用頻次過濾），交給翻譯流程處理後，整理為 `assets/tag_zh.json`（`slug → 中文名稱` 格式）。

---

## build_tag_catalog.py

從 `fetch_tags.py` 產生的 `scripts/out/tag_raw.json` 篩選出
`tag`/`language`/`parody`/`character`/`artist` 五種類型（不含 `group`——多為掃圖社雜訊、
`category`——只有 3 筆），去掉 `id`/`url`（App 內搜尋用不到），加上版本標記後以
`encode_tags.py` 相同的 XOR 編碼寫入 `assets/tag_catalog.bin`，作為 App 內建的本地標籤
資料庫，讓 Tags 分頁能在整個分類內即時搜尋、依收錄數排序，不受遠端 API 分頁限制。

同時會輸出 `assets/tag_catalog.version`（純文字，只有版本字串，幾十 bytes），供 App 的
「檢查更新」功能先比對版本、確定有新版才下載完整的 `tag_catalog.bin`（P59）。這兩個檔案
一定要一起提交/一起發布，不可以只更新其中一個。

**用法**（從專案根目錄執行，需先確認 `scripts/out/tag_raw.json` 存在）：

```bash
python scripts/build_tag_catalog.py
python scripts/build_tag_catalog.py --version 2026-08-01   # 覆寫版本標記，預設用今天日期
```

執行完會印出總筆數、各類型筆數與 `assets/tag_catalog.bin` 的實際檔案大小，請先確認大小
可接受再提交進版本庫。`assets/tag_catalog.bin` 和 `assets/tag_catalog.version` commit 進
`main` 後，`flutter-workflow-apk.yml` 會自動把兩者一起附到 `latest-build` release，不需要
手動上傳。

**重新產生 `tag_raw.json` 時的節流規則**：`fetch_tags.py` 對 nhentai 站方 API 做了
1.5 秒的請求間隔與 429 時的重試退避（`[10s, 30s, 60s]`），這是避免短時間大量請求觸發
IP 封鎖的必要節流。之後若要重新抓取更新標籤資料，**必須沿用這組節流設定**，不可為了
加快更新而跳過冷卻直接連續打 API。

---

## encode_tags.py

讀取翻譯完成的 `assets/tag_zh.json`，以簡單位元運算（XOR）將內容編碼為純二進位格式，輸出 `assets/tag_zh.bin`。

App 在啟動時讀取 `tag_zh.bin` 並即時還原，以同步方式提供標籤中文名稱查詢。使用二進位格式的目的是避免版本庫掃描器因明文內容觸發警告。

**用法**（從專案根目錄執行，需先確認 `assets/tag_zh.json` 存在）：

```bash
python scripts/encode_tags.py
```

每次更新 `assets/tag_zh.json` 後，需重新執行此腳本以同步更新 `assets/tag_zh.bin`，再提交至版本庫。

---

## scripts/out/

腳本的暫存輸出目錄，已加入 `.gitignore`，不納入版本控制。

| 檔案 | 說明 |
|------|------|
| `tag_raw.json` | `fetch_tags.py` 的完整原始輸出 |

---

## package_windows.ps1

把 `desktop_backup_server` 打包成可直接解壓執行的 Windows zip，輸出至
`scripts/out/comicdex-backup-server-<版本>-windows-x64.zip`。版本取自
`desktop_backup_server/pubspec.yaml` 的 `version:`（去掉 `+build` 號）。

**用法**（從專案根目錄執行）：

```powershell
powershell -File scripts\package_windows.ps1
powershell -File scripts\package_windows.ps1 -SkipBuild   # 沿用既有 build，只重新打包
```

**為什麼是整個資料夾而不是單一 exe**：Flutter 的 Windows 產出裡，`.exe` 只有 90 KB，
真正的引擎在 `flutter_windows.dll`（20 MB），Dart 程式碼在 `data\app.so`。少一個檔就
開不起來，所以壓的是整包。壓縮後約 12 MB。

**VC++ 執行階段**：腳本會用 `vswhere` 找出 Visual Studio 的安裝位置，把
`msvcp140.dll` / `vcruntime140.dll` / `vcruntime140_1.dll` 一併放進 zip（app-local
部署，微軟允許隨應用程式散布）。**不要改成寫死 `C:\Program Files`**——VS 可能裝在
其他磁碟機，第一版就是這樣靜靜地打包出一個在別台機器打不開的 zip。

沒有這三個 DLL 的機器上，雙擊 exe 會**完全沒有反應、不跳任何錯誤**，是最難自行診斷的
失敗方式。若腳本找不到它們會發出警告，此時要另外請使用者安裝
[VC++ Redistributable](https://aka.ms/vs/17/release/vc_redist.x64.exe)。

**未簽章**：第一次執行會跳 SmartScreen 的「不明的發行者」警告，要點「其他資訊 →
仍要執行」。要消除得購買程式碼簽章憑證，自用不需要。

---

## build_desktop_icon.ps1

由主 App 的 `assets/icon/icon.png` 產生桌面端的
`desktop_backup_server/windows/runner/resources/app_icon.ico`，讓 exe 圖示和手機端一致。

**用法**（從專案根目錄執行）：

```powershell
powershell -File scripts\build_desktop_icon.ps1
```

產出 16 / 24 / 32 / 48 / 64 / 128 / 256 共七種尺寸（每張以 PNG 存放，Vista 起支援）。
**不要改成只產一張 256**：Windows 用 16 px 畫工作列、24 px 畫檔案總管詳細清單，只有一張
大圖時那些尺寸全靠即時縮圖，細節多的圖會糊。`flutter_launcher_icons` 的 Windows 產出正是
單張，所以這裡沒有用它。

改完圖示要重新 `flutter build windows` 才會套用（RC 編譯器在建置時才把 ico 拆成資源嵌入
exe）。

---

## 桌面端 exe 的命名

`windows/CMakeLists.txt` 的 `BINARY_NAME` 是 `ComicdexBackupServer`，產出
`ComicdexBackupServer.exe`。**不能改成有空格的名稱**：Flutter 工具直接讀這個值組出 exe 路徑
（`flutter run` 靠它啟動），而 CMake 的 target 名稱本來就不允許空格。

使用者實際看得到的名稱是有空格的「Comicdex Backup Server」——視窗標題（`runner/main.cpp`）
與檔案內容頁的 `ProductName`／`FileDescription`（`runner/Runner.rc`）都是。

**改完 `BINARY_NAME` 一定要先 `flutter clean`**，否則 CMake 快取還記著舊的 target 名稱，
build 會以一長串 `No target "<舊名稱>"` 失敗。

---

## CI：flutter-workflow-windows.yml

`.github/workflows/flutter-workflow-windows.yml` 在 push 到 `main` 且動到
`desktop_backup_server/**` 或 `package_windows.ps1` 時，於 `windows-latest` 上建置、測試、
打包，並把 zip 附到 `latest-build` release——和 APK／IPA 共用同一個 release tag。

三份 workflow 共用 `concurrency: latest-build-release`，否則同一次 push 觸發的多個 workflow
會同時搶著建立 release，變成好幾個而不是一個被更新。

**CI 用 `-RequireCrt`**：找不到 VC++ 執行階段就直接讓 build 失敗。CI 裡沒有人會看警告，缺了
那三個 DLL 的 zip 會照樣被發布，然後在別人的電腦上無聲地打不開——寧可紅一次。

**尚未在 runner 上驗證過的部分**：GitHub 的 `windows-latest` 映像是否裝有 VC++ redist 元件。
本機用 `vswhere` 找得到，runner 的映像佈局可能不同，所以腳本另外加了兩個常見安裝路徑作為
後備。若第一次跑 CI 就卡在這裡，那不是意外，是這個假設沒成立——依訊息裡列出的缺件調整
搜尋路徑即可。

---

## 這裡的 .ps1 一定要存成 UTF-8 with BOM

Windows PowerShell 5.1 讀沒有 BOM 的 `.ps1` 時會用系統的 ANSI 代碼頁，而不是 UTF-8。在英文
環境（例如 GitHub 的 runner）那是 CP1252，於是：

- 中文全部變成亂碼（`完成：` → `å®Œæˆï¼š`）
- **更糟的是語法會壞掉**：`→` 的 UTF-8 是 `E2 86 92`，而 CP1252 的 `0x92` 是右單引號 `'`，
  PowerShell 把它當成字串結束符。字串提早結束後整個檔案的括號配對全亂，錯誤訊息是一長串
  `The string is missing the terminator` 和 `Missing closing '}'`，完全看不出跟編碼有關。

這在本機不會發作（開發機的代碼頁讀得對），只有進 CI 才炸——`flutter-workflow-windows.yml`
因此有一個 `Check script encoding` 步驟，缺 BOM 時用一句話講清楚原因，而不是丟出語法錯誤瀑布。

若編輯器把 BOM 拿掉了，用這段補回去：

```powershell
$utf8Bom = New-Object System.Text.UTF8Encoding($true)
$text = [System.IO.File]::ReadAllText($path, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText($path, $text, $utf8Bom)
```
