# Release procedure

1. Run dart format check, flutter analyze and flutter test. Review UI and docs/testing.md.
2. Build Windows on Windows and Linux on Linux; workflow `.github/workflows/build.yml` produces artifacts.
3. Windows portable includes the whole Release directory; Inno Setup builds a per-user installer with optional desktop shortcut.
4. Linux tar.gz includes native binary, lib/, data/, notices and launch.sh. It does not include Steam or game files.
5. Smoke-launch packaged builds. Check fonts, localization assets, window close, and offline behavior.
6. Create a GitHub prerelease tag, attach Windows ZIP, installer, Linux tar.gz and SHA256SUMS. Describe live-game limitations.
7. Never upload user profiles, tokens, saves, build caches or credentials. Keep source and license available.

Version 0.1 is an initial public preview. Neither Windows code signing nor an AppImage is provided.
