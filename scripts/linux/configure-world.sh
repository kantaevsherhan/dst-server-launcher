#!/usr/bin/env bash
set -euo pipefail
umask 077
here="$(cd -- "$(dirname -- "$0")" && pwd -P)"
id="$(cat "$here/cluster-id")"
[[ "$id" =~ ^dst_[a-z0-9_]+$ ]] || { echo 'Invalid cluster ID'; exit 2; }
dest="${1:-$HOME/games/dst-dedicated}"
parent="$HOME/.klei/DoNotStarveTogether"
cluster="$parent/$id"
mkdir -p -- "$parent"
if [ -e "$cluster" ]; then echo "World already exists: $cluster" >&2; exit 1; fi
bash "$here/install-dst-server.sh" "$dest"
read -r -s -p 'Enter Klei cluster token: ' token
printf '\n'
[ -n "$token" ] || { echo 'A token is required'; exit 2; }
stage="$(mktemp -d -- "$parent/.dst-setup.XXXXXX")"
trap 'rm -rf -- "$stage"' EXIT
cp -R -- "$here/$id/." "$stage/"
printf '%s\n' "$token" > "$stage/cluster_token.txt"
unset token
setup="$dest/mods/dedicated_server_mods_setup.lua"
mkdir -p -- "$dest/mods"
touch -- "$setup"
while IFS= read -r line; do
  [ -z "$line" ] || grep -Fqx -- "$line" "$setup" || printf '\n%s\n' "$line" >> "$setup"
done < "$here/workshop-setup.lua"
mv -nT -- "$stage" "$cluster"
[ ! -d "$stage" ] || { echo 'World already exists'; exit 1; }
trap - EXIT
echo 'Start each shard in its own terminal:'
for shard in Master Caves; do
  if [ -d "$cluster/$shard" ]; then printf 'bash %q --start-shard %q %q %q\n' "$here/install-dst-server.sh" "$cluster" "$shard" "$dest"; fi
done
