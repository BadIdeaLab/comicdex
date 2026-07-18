# API-README

nhentai API notes for nhviewer-universal.
All active endpoints use **v2** (`/api/v2/...`). The legacy v1 paths (`/api/galleries/...`) are no longer used.

---

## Active Endpoints (v2)

### Gallery list / search

```
GET https://nhentai.net/api/v2/galleries
    ?page=<n>

GET https://nhentai.net/api/v2/search
    ?query=<q>
    &page=<n>
    [&sort=popular|popular-today|popular-week|popular-month]
```

**Search query syntax**

| Example | Meaning |
|---------|---------|
| `language:chinese` | Filter by tag |
| `-language:english -language:japanese` | Exclude tags |
| `tag:full-color artist:foo` | AND multiple tags |

The app constructs the final query by joining the user's input, the selected language filter, and any blocked tags (each prefixed with `-`).

### Gallery detail

```
GET https://nhentai.net/api/v2/galleries/<id>
```

Returns full metadata including pages, tags, cover, thumbnail, upload date, and favorites count.

### Tag catalog

```
GET https://nhentai.net/api/v2/tags/<type>
    ?sort=popular
    &page=<n>
```

`<type>` values: `tag`, `language`, `parody`, `character`, `artist`, `group`, `category`

The app currently uses `tag` and `language` for the tag catalog browser.

---

## Image CDN

### CDN config

```
GET https://nhentai.net/api/v2/config
```

Returns the currently active CDN host pools:

| Field | Host pool | Used for |
|-------|-----------|----------|
| `image_servers` | `https://i<1-4>.nhentai.net` | Full page image paths from `pages[].path` |
| `thumb_servers` | `https://t<1-4>.nhentai.net` | `thumbnail.path`, `cover.path`, and page preview thumbnails |

The app resolves this via `NhentaiCdnConfigService`. If the config endpoint is unavailable, it falls back to the default `i1~i4` and `t1~t4` host lists.

### Thumbnails and covers

```
https://t<1-4>.nhentai.net/galleries/<media_id>/thumb.<ext>
https://t<1-4>.nhentai.net/galleries/<media_id>/cover.<ext>
```

For gallery detail responses, both `thumbnail.path` and `cover.path` are relative paths and must be resolved against `thumb_servers` (`t1~t4`). Do not resolve covers against `image_servers`; that causes failed cover downloads because cover assets live on the thumbnail CDN host pool.

### Full pages

```
https://i<1-4>.nhentai.net/galleries/<media_id>/<page>.<ext>
```

Extension is derived from the page type code in the API response (`j`→jpg, `p`→png, `g`→gif, `w`→webp).

---

## Authentication

The v2 API requires an API key for authenticated requests (favorites, account-linked operations).

```
Authorization: Key <api_key>
```

The key is stored in secure storage (`flutter_secure_storage`) and injected via `NhentaiApiKeyStore`.

---

## Language Fallback Strategy

Some language query strings return empty results intermittently. The app retries with fallback queries defined per `ComicLanguage`:

| Language | Primary query | Fallback |
|----------|--------------|---------|
| Chinese | `language:chinese` | `-language:english -language:japanese` |
| English | `language:english` | (no fallback) |
| Japanese | `language:japanese` | (no fallback) |
| All | _(empty)_ | (no fallback) |

---

## Blocked Tags

Blocked tags are stored locally and appended to every search as `-<query>` exclusions, e.g.:

```
language:chinese -tag:full-color -artist:xxx
```

---

## Notes

- The CDN config endpoint (`/api/v2/config`) is loaded on startup via `NhentaiCdnConfigService` to resolve the active image and thumbnail host pools.
- Favorites sync uses a separate paginated endpoint under `/api/v2/users/...`; see `NhentaiApiRemoteFavoriteGateway` for details.
