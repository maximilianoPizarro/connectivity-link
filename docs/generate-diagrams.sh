#!/usr/bin/env bash
# Generate PNG diagrams from Mermaid (.mmd) files for GitHub Pages.
# Requires: Node.js/npx and @mermaid-js/mermaid-cli
# Run from repo root: ./docs/generate-diagrams.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIAGRAMS_DIR="${SCRIPT_DIR}/diagrams"
OUTPUT_DIR="${SCRIPT_DIR}"

if ! command -v npx &>/dev/null; then
  echo "Error: npx not found. Install Node.js and npm."
  exit 1
fi

for mmd in system-architecture.mmd oidc-auth-flow.mmd installation-flow.mmd; do
  src="${DIAGRAMS_DIR}/${mmd}"
  base="${mmd%.mmd}"
  out="${OUTPUT_DIR}/${base}.png"
  if [[ -f "$src" ]]; then
    echo "Generating ${base}.png ..."
    npx --yes @mermaid-js/mermaid-cli@latest -i "$src" -o "$out" -b transparent 2>/dev/null || \
    npx --yes @mermaid-js/mermaid-cli@latest -i "$src" -o "$out" 2>/dev/null || true
    if [[ -f "$out" ]]; then
      echo "  -> $out"
    else
      echo "  Warning: failed to generate $out"
    fi
  else
    echo "Skip (not found): $src"
  fi
done

echo "Done. Add the generated PNGs to git and push for GitHub Pages."
