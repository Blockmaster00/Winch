#!/bin/bash

# bump the version number in main.lua
# arguments: 
#   $1 - the type of bump (major, minor, patch)

if [ -z "$1" ]; then
  echo "Error: No bump type specified"
  exit 1
fi

# repo root is one level up from this script, regardless of caller's cwd
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)
main_lua="$repo_root/winch_mod_local/main.lua"

# extract current major.minor.patch from main.lua
current=$(grep -oE 'VERSION *= *"[0-9]+\.[0-9]+\.[0-9]+"' "$main_lua" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
major=$(echo "$current" | cut -d. -f1)
minor=$(echo "$current" | cut -d. -f2)
patch=$(echo "$current" | cut -d. -f3)

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
    echo "Error: Invalid bump type specified"
    exit 1
    ;;
esac

new_version="${major}.${minor}.${patch}"
sed -i "s/\(VERSION *= *\"\)[0-9]*\.[0-9]*\.[0-9]*\(\"\)/\1${new_version}\2/" "$main_lua"

# regenerate Preview.png from the PDF template, if one exists
template="$repo_root/preview_template.pdf"
if [ -f "$template" ]; then
  python3 "$script_dir/generate_preview.py" "$new_version" --template "$template" --output "$repo_root/Preview.png"
fi