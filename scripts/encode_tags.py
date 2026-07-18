"""
將 scripts/tag_zh.json 編碼為 assets/tag_zh.bin（XOR 混淆）。

用法（從專案根目錄執行）：
    python scripts/encode_tags.py
"""
import pathlib

KEY = 0x42
src = pathlib.Path('scripts/tag_zh.json')
dst = pathlib.Path('assets/tag_zh.bin')

if not src.exists():
    raise FileNotFoundError(f'找不到 {src}，請先確認翻譯檔存在')

raw = src.read_bytes()
encoded = bytes(b ^ KEY for b in raw)
dst.write_bytes(encoded)
print(f'已編碼 {len(raw):,} bytes → {dst}')
