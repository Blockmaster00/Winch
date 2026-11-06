#!/usr/bin/env bash
set -euo pipefail

# bump the version number in main.lua
# arguments: 
#   $1 - the type of bump (major, minor, patch)

if [ -z "${1:-}" ]; then
  echo "Error: No bump type specified" >&2
  exit 1
fi


# repo root is one level up from this script, regardless of caller's cwd
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)
main_lua="$repo_root/mod/main.lua"

if [ ! -f "$main_lua" ]; then
  echo "Error: Mod entrypoint not found: $main_lua" >&2
  exit 1
fi

if [ -f "$repo_root/.env" ]; then
  set -a
  # shellcheck source=/dev/null
  source "$repo_root/.env"
  set +a
fi

# extract current major.minor.patch from main.lua
current=$(grep -oE 'VERSION *= *"[0-9]+\.[0-9]+\.[0-9]+"' "$main_lua" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || true)
if [[ ! "$current" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Error: Could not find a valid major.minor.patch VERSION in $main_lua" >&2
  exit 1
fi
IFS=. read -r major minor patch <<< "$current"

case "$1" in
  major)
    major=$((major+1)); minor=0; patch=0
    ;;
  minor)
    minor=$((minor+1)); patch=0
    ;;
  patch)
    patch=$((patch+1))
    ;;
  *)
    echo "Error: Invalid bump type specified" >&2
    exit 1
    ;;
esac

new_version="${major}.${minor}.${patch}"
sed -i "s/\(VERSION *= *\"\)[0-9]*\.[0-9]*\.[0-9]*\(\"\)/\1${new_version}\2/" "$main_lua"
echo "Bumped version to $new_version"

# regenerate Preview.png from the PDF template, if one exists
template="$repo_root/preview_template.pdf"
if [ -f "$template" ]; then
  # venvs use bin/ on Linux and Scripts/ on Windows; fall back to a PATH interpreter otherwise
  if [ -x "$repo_root/.venv/bin/python" ]; then
    python_bin="$repo_root/.venv/bin/python"
  elif [ -x "$repo_root/.venv/Scripts/python.exe" ]; then
    python_bin="$repo_root/.venv/Scripts/python.exe"
  elif command -v python3 >/dev/null 2>&1; then
    python_bin="python3"
  else
    python_bin="python"
  fi

  font_args=()
  if [ -n "${JUMBOX_FONT_FILE:-}" ]; then
    font_args+=(--font-file "$JUMBOX_FONT_FILE")
  fi
  "$python_bin" "$script_dir/generate_preview.py" "$new_version" --template "$template" --output "$repo_root/Preview.png" --font "JumboxBold" "${font_args[@]}"
fi