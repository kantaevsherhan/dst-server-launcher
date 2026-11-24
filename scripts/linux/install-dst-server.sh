#!/usr/bin/env bash
set -euo pipefail
DEFAULT_DEST="$HOME/games/dst-dedicated"
show_deps() {
  [ ! -r /etc/os-release ] || . /etc/os-release
  case "${ID:-}" in
    fedora) echo 'sudo dnf install glibc.i686 libstdc++.i686 libcurl.i686 curl tar gzip' ;;
    manjaro|arch) echo 'Enable multilib, then: sudo pacman -Syu --needed lib32-gcc-libs lib32-libcurl curl tar gzip' ;;
    debian|ubuntu|linuxmint) printf '%s\n' 'sudo dpkg --add-architecture i386' 'sudo apt-get update' 'sudo apt-get install lib32gcc-s1 lib32stdc++6 libcurl4:i386 curl ca-certificates tar' ;;
    *) echo 'Install SteamCMD, curl, tar and DST runtime libraries for your distribution.' ;;
  esac
}
case "${1:-}" in
  --help|-h)
    echo "Install: bash install-dst-server.sh [absolute-install-dir]"
    echo "Show system dependencies: bash install-dst-server.sh --deps"
    echo "Start existing world: bash install-dst-server.sh --start-shard /path/to/conf/cluster Master|Caves [install-dir]"
    exit 0 ;;
  --deps) show_deps; exit 0 ;;
  --start-shard)
    [ "$#" -ge 3 ] && [ "$#" -le 4 ] || { echo "Use --help" >&2; exit 2; }
    case "$3" in Master|Caves) ;; *) echo "Expected Master or Caves" >&2; exit 2;; esac
    CLUSTER="$(cd -- "$2" && pwd -P)"
    [ -s "$CLUSTER/cluster_token.txt" ] && [ -f "$CLUSTER/cluster.ini" ] && [ -f "$CLUSTER/$3/server.ini" ] || { echo "Missing cluster token or configuration" >&2; exit 1; }
    CONF="$(dirname -- "$CLUSTER")"
    cd -- "${4:-$DEFAULT_DEST}/bin64"
    exec ./dontstarve_dedicated_server_nullrenderer_x64 -console -persistent_storage_root "$(dirname -- "$CONF")" -conf_dir "$(basename -- "$CONF")" -cluster "$(basename -- "$CLUSTER")" -shard "$3" ;;
esac
[ "$#" -le 1 ] || { echo "Use --help" >&2; exit 2; }
DEST="${1:-$DEFAULT_DEST}"
case "$DEST" in /*) ;; *) echo 'Use an absolute install directory' >&2; exit 2;; esac
[ "$(realpath -m -- "$DEST")" != / ] || { echo 'Select a dedicated server directory' >&2; exit 2; }
[ "$(uname -sm)" = "Linux x86_64" ] || { echo "Linux x86_64 required" >&2; exit 1; }
STEAMCMD_DIR="$HOME/.local/share/dst-launcher/steamcmd"
if command -v steamcmd >/dev/null; then STEAMCMD_BIN="$(command -v steamcmd)"
elif [ -x /usr/games/steamcmd ]; then STEAMCMD_BIN=/usr/games/steamcmd
else
  STEAMCMD_BIN="$STEAMCMD_DIR/steamcmd.sh"
  if [ ! -x "$STEAMCMD_BIN" ]; then
    mkdir -p -- "$STEAMCMD_DIR"
    archive="$(mktemp)"
    trap 'rm -f -- "$archive"' EXIT
    curl --fail --location --proto '=https' --tlsv1.2 https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz -o "$archive"
    tar -xzf "$archive" -C "$STEAMCMD_DIR"
  fi
fi
mkdir -p -- "$DEST"
"$STEAMCMD_BIN" +force_install_dir "$DEST" +login anonymous +app_update 343050 validate +quit </dev/null || { show_deps >&2; exit 1; }
BIN="$DEST/bin64/dontstarve_dedicated_server_nullrenderer_x64"
[ -x "$BIN" ] || { echo "Missing server binary: $BIN" >&2; exit 1; }
libs="$(cd -- "$DEST/bin64" && ldd ./dontstarve_dedicated_server_nullrenderer_x64)"
if [[ "$libs" == *"not found"* ]]; then printf '%s\n' "$libs" >&2; show_deps >&2; exit 1; fi
printf 'Dedicated server installed: %s\n' "$DEST"
