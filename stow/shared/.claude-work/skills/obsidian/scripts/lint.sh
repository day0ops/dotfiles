#!/usr/bin/env bash
# shellcheck shell=bash
set -e

# Vault health check: orphaned notes, broken wikilinks, missing frontmatter.
# Read-only - never modifies the vault. Usage: lint.sh <vault-path>

VAULT="${1:?usage: lint.sh <vault-path>}"

if [[ ! -d "$VAULT" ]]; then
  echo "error: vault not found: $VAULT" >&2
  exit 1
fi

cd "$VAULT"

targets_file="$(mktemp)"
titles_file="$(mktemp)"
attachments_file="$(mktemp)"
trap 'rm -f "$targets_file" "$titles_file" "$attachments_file"' EXIT

# Every wikilink target in the vault, normalized to a bare title (strip
# "[[", display text after "|", and heading anchors after "#"). Templates are
# excluded since they contain placeholder links (e.g. a sample company name)
# that aren't meant to resolve to a real note.
rg -o --no-filename --type md '\[\[[^]|#]+' -g '!.obsidian' -g '!.trash' -g '!_templates' . \
  | sed 's/^\[\[//' | sort -u >"$targets_file"

# Every note's title (filename without extension), vault-wide.
fd -tf -e md . -E .obsidian -E .trash | while read -r file; do
  basename "$file" .md
done | sort -u >"$titles_file"

# Every non-markdown attachment's filename (images, PDFs, ...), extension
# included, since embeds like ![[foo.png]] reference the full filename.
fd -tf -E .obsidian -E .trash -E '*.md' . | while read -r file; do
  basename "$file"
done | sort -u >"$attachments_file"

echo "== Orphaned notes (no incoming wikilinks) =="
fd -tf -e md . -E .obsidian -E .trash -E Daily -E Ideas -E Archive -E _templates | while read -r file; do
  title="$(basename "$file" .md)"
  grep -qxF "$title" "$targets_file" || echo "$file"
done

echo
echo "== Broken wikilinks (target file not found) =="
comm -23 "$targets_file" "$titles_file" | while read -r target; do
  grep -qxF "$target" "$attachments_file" || echo "$target"
done

echo
echo "== Notes missing required frontmatter fields (id/aliases/tags/categories) =="
fd -tf -e md . -E .obsidian -E .trash -E _templates | while read -r file; do
  missing=()
  for field in id aliases tags categories; do
    rg -q "^${field}:" "$file" || missing+=("$field")
  done
  [[ ${#missing[@]} -gt 0 ]] && echo "$file: missing ${missing[*]}" || true
done
