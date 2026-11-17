#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
flutter pub get
flutter analyze
flutter test
flutter build linux --release
mkdir -p dist
cp README.md LICENSE THIRD_PARTY_NOTICES.md scripts/linux/launch.sh build/linux/x64/release/bundle/
chmod +x build/linux/x64/release/bundle/launch.sh
tar -czf dist/dst-server-launcher-linux-x64.tar.gz -C build/linux/x64/release/bundle .
