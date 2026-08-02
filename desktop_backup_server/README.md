# Comicdex Backup Server (Windows)

Receives backups from the Comicdex mobile app over your local network. Nothing
leaves your machine — there is no cloud service, no account, and no third-party
API involved.

## How it works

The desktop keeps a **mirror** of the phone's data rather than a pile of archive
files:

```
<backup folder>/
└─ Pixel-8/                          ← one folder per device
   ├─ manifest.json
   ├─ db/database-<timestamp>-v<schema>.db
   └─ downloads/177013/pages/1.webp  ← same layout as on the phone
```

Because the mirror *is* the checkpoint, backups resume for free: the phone asks
what already exists and only sends the difference. Close the app, reboot either
machine, come back days later — rerunning simply continues where it stopped.

Only the pairing PIN does not survive a restart (see below).

## Running it

```sh
flutter run -d windows
```

Then enter the address and PIN shown in the window into the phone app.

### First run: two things that commonly block the phone

1. **Windows Firewall.** The first launch pops a prompt asking whether to allow
   the app on private networks. If that is dismissed, the phone simply times out
   with no useful error — it looks identical to typing the wrong address. Allow
   it for private networks.
2. **Developer Mode** (build machines only). `flutter run`/`flutter build windows`
   needs symlink support for plugins:
   ```sh
   start ms-settings:developers
   ```
   Tests do not need this — they run on the Dart VM.

### Multiple addresses

The window lists every network adapter, not a guessed "best" one. Dev machines
usually also have WSL, Hyper-V or VirtualBox adapters that the phone cannot
reach, so pick the one matching your actual Wi-Fi/Ethernet connection.

## Settings

Settings live in a plain JSON file you can read and edit by hand:

```
%APPDATA%\ComicdexBackupServer\config.json
```

```json
{
  "backupRootPath": "E:\\ProgramData\\ComicdexBackups",
  "port": 8787,
  "maxDbSnapshots": 10,
  "language": "system"
}
```

A malformed or missing value falls back to its default rather than blocking
startup, so editing it is safe.

The path is chosen deliberately rather than via `path_provider`. Flutter's
`shared_preferences` on Windows resolves under
`%APPDATA%\<CompanyName>\<ProductName>`, both taken from the executable's
version metadata in `windows/runner/Runner.rc` — so renaming the app silently
moves the store and orphans every setting. Settings must not depend on metadata
that is expected to change.

Note that the **device list is not stored here**. Which devices exist, and where
each one's database lives, is derived by scanning the backup folder. A registry
would be a second source of truth that drifts the moment a folder is moved or
copied; the directory tree is the honest record.

## Safety properties worth knowing

- **The PIN is regenerated on every launch** and lives only in memory. Repeated
  wrong guesses temporarily block that address — a 6-digit PIN is only a million
  combinations, so without throttling it would be decorative on a LAN.
- **Nothing lands on its final path until its checksum is verified.** Transfers
  write to a `.part` file first, so an interrupted upload can never leave a
  truncated file that a later sync would skip as "already have it".
- **A missing backup folder is a hard error, not a fallback.** If the configured
  folder is gone (external drive unplugged, drive letter changed) the server
  refuses requests instead of quietly creating an empty one — otherwise the
  phone would see an empty mirror and re-upload its entire library.
- **Deletions are never mirrored automatically.** When the phone asks to clean
  up, the desktop shows exactly what would be removed and waits for explicit
  confirmation. A backup that silently follows deletions would let one
  accidental phone-side delete destroy the backup too.
- **API keys are not part of a backup.** The phone stores those in its OS
  keychain; after restoring you sign in again.

## Tests

```sh
flutter test
```

The HTTP layer is tested against a real `HttpServer` on an ephemeral port with a
real client — status codes, streaming, and atomicity only prove out when the
actual stack runs.
