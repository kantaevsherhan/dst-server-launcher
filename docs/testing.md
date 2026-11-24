# Validation record

Automated checks: `flutter analyze`, `flutter test` (models, generators, Workshop parsing, Linux shell quoting,
Steam manifests/libraries, atomic profile storage, backup/restore/traversal, process state/readiness/crash/timeout,
secret redaction, RU/EN keys, first-run desktop widgets, wizard validation).
`integration_test/desktop_smoke_test.dart` is an opt-in native smoke test, not a substitute for live DST gameplay.

Before claiming live game integration complete, manually verify:

- Windows Steam Tools 343050 on default and other-disk libraries, paths with spaces/Cyrillic.
- Steam Client and SteamCMD on Debian, Ubuntu, Mint, Manjaro and Fedora; inspect missing-library recovery.
- A real private Klei token, one and two shards, connection by an external friend, clean graceful shutdown/save/restart.
- Public Workshop mod and collection, per-shard enablement and actual download logs; offline/rate-limit behavior.
- Import an already stopped real cluster (especially custom mods); compare preserved world files.
- Backup/restore a real played world, original retained on failure, secrets omitted when sharing archives.
- Close policies and abrupt GUI termination; no duplicate server process after reopening.
- Keyboard Tab/Enter/Escape, screen-reader names, high DPI 125–200%, dark/light, RU/EN, native file pickers.

Not yet proven by automated tests: Klei acceptance, game console stdin in every DST build, internet reachability,
CGNAT traversal, real Workshop gameplay compatibility or all distro runtime combinations. The UI never simulates them.

## Observed on 2026-11-17

- Flutter analyze: no issues. 56 unit/widget tests passed on Windows; the first CI run passed the same checks on Windows and Linux.
- Windows release built locally with VS 2022 C++ Build Tools; both Windows installer/portable and Linux tar.gz packaging passed GitHub Actions.
- The native release window launched and exposed the expected RU accessibility tree. Window screenshot capture was unreliable; documentation screenshots are real Flutter renderer captures from test/visual/render_screenshots.dart, not mockups.
- Screenshot inspection found and fixed missing Cyrillic display glyphs (Manrope replaces Outfit), a narrow hero banner and navigation ink layers. The enlarged-text check caught and fixed the status-row overflow at 200%.
- The local Windows native debug integration test compiled but Windows Application Control blocked execution. No security settings were changed. Native smoke tests are also configured on clean CI hosts.
- Valve GetPublishedFileDetails returned result=1, title Global Positions and consumer_app_id=322330 for public Workshop ID 378160973.
- Actual DST gameplay/Klei login and internet joining remain unverified; no real token was requested, stored or published during development.

Final safety regressions cover start/backup exclusion, active-profile snapshot rejection, imported Lua preservation and nested import destinations. Native CI discovered an unbounded titlebar height; the area is now constrained to 40 logical pixels.

## Installer interface, 2026-11-22

Headless widget tests cover the default local OS, selecting the other OS, returning from its installation guide, English with enlarged text, and a local wizard through the configuration review. Process tests inject fake shards for save, restart and delayed readiness. Filesystem tests use temporary directories for cluster creation, backups, restore and import. Workshop collection responses are fixtures. Screenshots cover light and dark themes, including the horizontal scene. Native launch, live Steam installation, Klei authentication and multiplayer were excluded from this check.

## 0.2.1 verification

A Windows smoke test used the existing game's ASCII short path on a Cyrillic profile. Master and Caves both loaded the existing cluster token, generated their worlds, reached simulation and wrote saves. Master registered and both processes exited with code zero after the console shutdown command. Joining from a second internet connection remains unverified. Local per-account DST subscription files were identified independently of installed Workshop content. Linux desktop packaging and standalone headless script checks do not establish runtime compatibility with every distribution.
