#!/bin/bash
set -euo pipefail

# === CONFIG ===
SOURCE="shader-ex-107"
FILE="README.md"
REMOTE="origin"
# =================

# ensure up to date
git fetch --prune --quiet "$REMOTE"

# get canonical README into temp
TMP=$(mktemp)
if ! git show "$REMOTE/$SOURCE:$FILE" > "$TMP" 2>/dev/null; then
  echo "ERROR: cannot read $FILE from $REMOTE/$SOURCE"
  rm -f "$TMP"
  exit 1
fi

# get list of remote branches (excluding HEAD pointer)
branches=$(git for-each-ref --format='%(refname:short)' "refs/remotes/$REMOTE" \
  | grep -v "^$REMOTE/HEAD$" \
  | sed "s#^$REMOTE/##")

for br in $branches; do
  if [ "$br" = "$SOURCE" ]; then
    continue
  fi

  echo ">>> Processing branch: $br"

  # create or reset local branch to match remote
  git checkout -B "$br" "$REMOTE/$br"

  # compare
  if [ -f "$FILE" ] && diff -q "$FILE" "$TMP" > /dev/null 2>&1; then
    echo "    $FILE already up to date; skipping."
    continue
  fi

  # copy & commit
  cp "$TMP" "$FILE"
  git add "$FILE"

  if git diff --cached --quiet; then
    echo "    nothing to commit (unexpected); skipping."
    continue
  fi

  git commit -m "Sync README from $SOURCE"
  git push "$REMOTE" "$br"
done

# cleanup
rm -f "$TMP"
echo "All done."
