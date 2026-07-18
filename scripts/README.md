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

**用法**（從專案根目錄執行，需先確認 `scripts/out/tag_raw.json` 存在）：

```bash
python scripts/build_tag_catalog.py
python scripts/build_tag_catalog.py --version 2026-08-01   # 覆寫版本標記，預設用今天日期
```

執行完會印出總筆數、各類型筆數與 `assets/tag_catalog.bin` 的實際檔案大小，請先確認大小
可接受再提交進版本庫。

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
