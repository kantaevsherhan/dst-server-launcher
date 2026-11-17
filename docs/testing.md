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
