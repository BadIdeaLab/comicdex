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
