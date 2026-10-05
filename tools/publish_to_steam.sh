#!/bin/bash

changenote="$1"

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)

# load STEAM_USER from .env, if present (export so steamcmd subprocess sees it)
if [ -f "$repo_root/.env" ]; then
  set -a
  source "$repo_root/.env"
  set +a
fi

if [ -z "$STEAM_USER" ]; then
  echo "Error: STEAM_USER is not set (define it in .env or export it beforehand)"
  exit 1
fi

# check if preview file below 1MB else exit
if ! [ $(stat -c%s "$repo_root/Preview.png") -lt 1048576 ]; then
  echo "Preview file is above 1MB"
  exit 1
fi

# check if upload.vdf exists
if ! [ -f "$repo_root/upload.vdf" ]; then
  echo "Error: upload.vdf not found in repository root"
  exit 1
fi

# update changenote in upload.vdf to following format: "Version: <VERSION_NUMBER> - <CHANGENOTE>" or "Version: <VERSION_NUMBER>" if no changenote is provided
version=$(grep -oE 'VERSION *= *"[0-9]+\.[0-9]+\.[0-9]+"' "$repo_root/mod/main.lua" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
if [ -n "$changenote" ]; then
  sed -i "s/\(\"changenote\" *\"\).*\(\"\)/\1Version: $version - $changenote\2/" "$repo_root/upload.vdf"
else
  sed -i "s/\(\"changenote\" *\"\).*\(\"\)/\1Version: $version\2/" "$repo_root/upload.vdf"
fi


steamcmd \
  +login "${STEAM_USER}" \
  +workshop_build_item "$repo_root/upload.vdf" \
  +quit