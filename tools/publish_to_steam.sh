#!/bin/bash

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

steamcmd \
  +login "${STEAM_USER}" \
  +workshop_build_item "$repo_root/upload.vdf" \
  +quit