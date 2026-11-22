#!/usr/bin/env bash
# Check that every post with executable code has frozen results in _freeze/
# that match its current source.
#
# With `freeze: true`, Quarto never re-executes a post, even after its source
# has changed, so it would quietly publish stale results. Quarto stores the MD5
# of the source (with LF line endings) as "hash" in the frozen results; we
# compare against it here.
#
# Usage: _scripts/check-freeze.sh [posts/<slug>/index.qmd ...]   (default: all posts)
set -euo pipefail

if [ "$#" -gt 0 ]; then
  files=("$@")
else
  shopt -s nullglob
  files=(posts/*/index.qmd)
fi
# bash 3.2 (macOS) treats an empty array as unbound under `set -u`.
[ "${#files[@]}" -gt 0 ] || exit 0

status=0
for qmd in "${files[@]}"; do
  [ -f "$qmd" ] || continue
  # Posts without code cells are not executed, so they have nothing to freeze.
  grep -qE '^[[:space:]]*```+[[:space:]]*\{' "$qmd" || continue

  dir=$(dirname "$qmd")
  name=$(basename "$qmd" .qmd)
  json="_freeze/$dir/$name/execute-results/html.json"

  if [ ! -f "$json" ]; then
    echo "::error file=$qmd::No frozen results. Run 'quarto render $qmd' locally and commit the changes in _freeze/."
    status=1
    continue
  fi

  expected=$(sed 's/\r$//' "$qmd" | md5sum | cut -d' ' -f1)
  frozen=$(sed -n 's/^ *"hash": *"\([0-9a-f]*\)".*/\1/p' "$json" | head -n1)
  if [ "$expected" != "$frozen" ]; then
    echo "::error file=$qmd::Source changed after rendering. Run 'quarto render $qmd' locally and commit the changes in _freeze/."
    status=1
  else
    echo "ok: $qmd"
  fi
done

exit $status
