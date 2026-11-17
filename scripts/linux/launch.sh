#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
exec ./dst_server_launcher "$@"
