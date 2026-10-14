#!/usr/bin/env bash
set -euo pipefail

changenote="${1:-}"

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)

# load STEAM_USER from .env, if present (export so steamcmd subprocess sees it)
if [ -f "$repo_root/.env" ]; then
  set -a
  # shellcheck source=/dev/null
  source "$repo_root/.env"
  set +a
fi

if [ -z "${STEAM_USER:-}" ]; then
  echo "Error: STEAM_USER is not set (define it in .env or export it beforehand)" >&2
  exit 1
fi

if ! command -v steamcmd >/dev/null 2>&1; then
  echo "Error: steamcmd not found on PATH" >&2
  exit 1
fi

preview="$repo_root/Preview.png"
if [ ! -f "$preview" ]; then
  echo "Error: Preview.png not found in repository root" >&2
  exit 1
fi

# check if preview file is below 1MB (wc -c is portable across GNU/BSD/Windows stat flavors)
preview_size=$(wc -c < "$preview")
if [ "$preview_size" -ge 1048576 ]; then
  echo "Error: Preview file is above 1MB" >&2
  exit 1
fi

# check if upload.vdf exists
upload_vdf="$repo_root/upload.vdf"
if [ ! -f "$upload_vdf" ]; then
  echo "Error: upload.vdf not found in repository root" >&2
  exit 1
fi

# update changenote in upload.vdf to following format: "Version: <VERSION_NUMBER> - <CHANGENOTE>" or "Version: <VERSION_NUMBER>" if no changenote is provided
version=$(grep -oE 'VERSION *= *"[0-9]+\.[0-9]+\.[0-9]+"' "$repo_root/mod/main.lua" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
if [ -n "$changenote" ]; then
  sed -i "s/\(\"changenote\" *\"\).*\(\"\)/\1Version: $version - $changenote\2/" "$upload_vdf"
else
  sed -i "s/\(\"changenote\" *\"\).*\(\"\)/\1Version: $version\2/" "$upload_vdf"
fi

steamcmd \
  +login "${STEAM_USER}" \
  +workshop_build_item "$upload_vdf" \
  +quit