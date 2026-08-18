#!/usr/bin/env bash
set -euo pipefail

# Builds the plugin, then copies main.js/manifest.json/styles.css into an
# Obsidian vault's plugins folder.

if [[ $# -ne 1 ]]; then
	echo "Usage: $0 /path/to/YourVault  (also accepts .../.obsidian or .../.obsidian/plugins)" >&2
	exit 1
fi

INPUT_DIR=$(cd "$1" && pwd)
REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PLUGIN_ID=$(node -pe "require('$REPO_DIR/manifest.json').id")

# Accept a vault root, its .obsidian folder, or its .obsidian/plugins folder.
if [[ "$(basename "$INPUT_DIR")" == "plugins" && "$(basename "$(dirname "$INPUT_DIR")")" == ".obsidian" ]]; then
	PLUGINS_DIR="$INPUT_DIR"
elif [[ "$(basename "$INPUT_DIR")" == ".obsidian" ]]; then
	PLUGINS_DIR="$INPUT_DIR/plugins"
elif [[ -d "$INPUT_DIR/.obsidian" ]]; then
	PLUGINS_DIR="$INPUT_DIR/.obsidian/plugins"
else
	echo "Error: '$INPUT_DIR' doesn't look like an Obsidian vault (no .obsidian folder found)." >&2
	exit 1
fi

TARGET_DIR="$PLUGINS_DIR/$PLUGIN_ID"

echo "Building..."
(cd "$REPO_DIR" && npm run build)

mkdir -p "$TARGET_DIR"
cp "$REPO_DIR/main.js" "$REPO_DIR/manifest.json" "$TARGET_DIR/"
if [[ -f "$REPO_DIR/styles.css" ]]; then
	cp "$REPO_DIR/styles.css" "$TARGET_DIR/"
fi

echo "Deployed to: $TARGET_DIR"
echo "Reload Obsidian (or use the Hot Reload plugin) to pick up the changes."
