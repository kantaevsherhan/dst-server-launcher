# DST Server Launcher

Windows/Linux x64 desktop only. Read docs/architecture.md and docs/security.md first.
Use Flutter 3.47.7 / Dart 3.13.5; lock dependencies. No Docker, web, mobile or game assets.
Never commit Klei tokens, Steam credentials, cluster saves, local user paths or generated binaries.
Domain models validate every write. UI uses Provider/ChangeNotifier; no process spawning in widgets.
All OS processes use executable + argument arrays. No shell interpolation with user input.
Steam server app is 343050; Workshop consumer app is 322330.
Keep runtime process state separate from profile JSON. No invented player counts/readiness/progress.
Never replace an existing world silently. Stop both shards before backup/restore/mod changes.
Use ARB strings for RU/EN and semantic theme tokens. Check 900/1050/1440 widths, keyboard focus and scaled text.
Run dart format, flutter analyze, flutter test and platform release builds after changes.
Record unverified live Steam/Klei behavior honestly in docs/testing.md.
No extra agent delegation is required by this repository.
