"""
Fetches all nhentai tag catalog entries and outputs a raw JSON file.

Usage:
    python scripts/fetch_tags.py --output tag_raw.json

The output JSON is a list of objects:
    [{"id": 1, "type": "tag", "name": "full-color", "slug": "full-color", "url": "/tag/full-color/", "count": 12345}, ...]

Pass the raw JSON to Claude to translate into assets/tag_zh.json.
"""

import argparse
import json
import time
import urllib.request
import urllib.error

TYPES = ['tag', 'language', 'parody', 'character', 'artist', 'group', 'category']

REQUEST_DELAY = 1.5   # seconds between requests
RETRY_DELAYS = [10, 30, 60]  # seconds to wait on 429, per retry attempt


def fetch_page(url: str) -> dict | None:
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    }
    req = urllib.request.Request(url, headers=headers)
    for attempt, wait in enumerate([0] + RETRY_DELAYS):
        if wait:
            print(f'    rate-limited, waiting {wait}s before retry {attempt}...')
            time.sleep(wait)
        try:
            with urllib.request.urlopen(req, timeout=15) as resp:
                return json.loads(resp.read())
        except urllib.error.HTTPError as e:
            if e.code == 429:
                continue
            print(f'  HTTP {e.code} on {url}, skipping')
            return None
    print(f'  gave up after {len(RETRY_DELAYS)} retries: {url}')
    return None


def fetch_all() -> list[dict]:
    results = []
    for tag_type in TYPES:
        print(f'Fetching type: {tag_type}')
        page = 1
        while True:
            url = f'https://nhentai.net/api/v2/tags/{tag_type}?sort=popular&page={page}'
            data = fetch_page(url)
            if data is None:
                break
            items = data.get('result', [])
            results.extend(items)
            num_pages = data.get('num_pages', 1)
            print(f'  page {page}/{num_pages} — {len(items)} items (total so far: {len(results)})')
            if page >= num_pages:
                break
            page += 1
            time.sleep(REQUEST_DELAY)
    return results


def main():
    parser = argparse.ArgumentParser(description='Fetch nhentai tag catalog')
    parser.add_argument('--output', default='tag_raw.json', help='Output file path')
    args = parser.parse_args()

    tags = fetch_all()

    with open(args.output, 'w', encoding='utf-8') as f:
        json.dump(tags, f, ensure_ascii=False, indent=2)

    print(f'\nDone. Wrote {len(tags)} tags to {args.output}')


if __name__ == '__main__':
    main()
