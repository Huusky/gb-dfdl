#!/usr/bin/env bash
# Regenerates every fixture in test/data/ from scratch.
# Requires: git >= 2.45 (SHA-256 bundle support), python3.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA="$HERE/data"
SCRATCH="$HERE/.scratch"
mkdir -p "$DATA"
rm -rf "$SCRATCH"
mkdir -p "$SCRATCH"

# Deterministic identity/dates so fixtures are stable across runs.
export GIT_AUTHOR_NAME="Fixture Bot"
export GIT_AUTHOR_EMAIL="fixture@example.invalid"
export GIT_COMMITTER_NAME="Fixture Bot"
export GIT_COMMITTER_EMAIL="fixture@example.invalid"
export GIT_AUTHOR_DATE="2026-01-01T00:00:00+0000"
export GIT_COMMITTER_DATE="2026-01-01T00:00:00+0000"

make_repo() {  # $1 = repo path, $2 = object-format
  local repo="$1" fmt="$2"
  git init --quiet --object-format="$fmt" --initial-branch=main "$repo"
  ( cd "$repo"
    printf 'hello git bundle\n' > greeting.txt
    git add greeting.txt
    git commit --quiet -m "Initial commit"
    git tag v1.0 )
}

# --- valid v2 / SHA-1 ---
make_repo "$SCRATCH/repo-sha1" sha1
git -C "$SCRATCH/repo-sha1" bundle create --quiet "$DATA/valid-v2-sha1.bundle" --all

# --- valid v3 / SHA-256 ---
make_repo "$SCRATCH/repo-sha256" sha256
git -C "$SCRATCH/repo-sha256" bundle create --quiet "$DATA/valid-v3-sha256.bundle" --all

echo "valid fixtures written to $DATA"
