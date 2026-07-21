"""
將 scripts/out/tag_raw.json 篩選、精簡、加上版本標記後，
以與 encode_tags.py 相同的 XOR 編碼寫入 assets/tag_catalog.bin。

只保留這幾種類型：tag / language / parody / character / artist
（group 多為掃圖社雜訊、category 只有 3 筆，不收錄）。

用法（從專案根目錄執行，需先用 fetch_tags.py 產生 scripts/out/tag_raw.json）：
    python scripts/build_tag_catalog.py
    python scripts/build_tag_catalog.py --version 2026-08-01
"""
import argparse
import json
import pathlib
from collections import Counter
from datetime import date

KEY = 0x42
INCLUDED_TYPES = ('tag', 'language', 'parody', 'character', 'artist')

SRC = pathlib.Path('scripts/out/tag_raw.json')
DST = pathlib.Path('assets/tag_catalog.bin')
VERSION_DST = pathlib.Path('assets/tag_catalog.version')


def build_entries(raw: list[dict]) -> list[dict]:
    entries = [
        {'t': item['type'], 'n': item['name'], 's': item['slug'], 'c': item['count']}
        for item in raw
        if item.get('type') in INCLUDED_TYPES
    ]
    entries.sort(key=lambda e: (e['t'], -e['c']))
    return entries


def main():
    parser = argparse.ArgumentParser(description='Build the local tag catalog asset')
    parser.add_argument(
        '--version',
        default=date.today().isoformat(),
        help='Version string embedded in the catalog envelope (default: today, ISO date)',
    )
    args = parser.parse_args()

    if not SRC.exists():
        raise FileNotFoundError(f'找不到 {SRC}，請先執行 scripts/fetch_tags.py')

    raw = json.loads(SRC.read_text(encoding='utf-8'))
    entries = build_entries(raw)
    if not entries:
        raise ValueError('篩選後沒有任何標籤，請確認 tag_raw.json 內容')

    payload = {'version': args.version, 'entries': entries}
    payload_json = json.dumps(payload, ensure_ascii=False, separators=(',', ':'))
    payload_bytes = payload_json.encode('utf-8')
    encoded = bytes(b ^ KEY for b in payload_bytes)

    DST.parent.mkdir(parents=True, exist_ok=True)
    DST.write_bytes(encoded)
    VERSION_DST.write_text(args.version, encoding='utf-8')

    counts = Counter(e['t'] for e in entries)
    size = DST.stat().st_size
    size_display = f'{size / 1024 / 1024:.2f} MB' if size >= 1024 * 1024 else f'{size / 1024:.1f} KB'

    print(f'version: {args.version}')
    print(f'entries: {len(entries)} total')
    for t in INCLUDED_TYPES:
        print(f'  {t}: {counts.get(t, 0)}')
    print(f'wrote {DST} ({size:,} bytes, {size_display})')
    print(f'wrote {VERSION_DST}')


if __name__ == '__main__':
    main()
