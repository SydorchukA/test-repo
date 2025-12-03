#!/usr/bin/env bash
# Cleanup git branches — simple version
# Comments in English.

set -euo pipefail

### === CONFIG === ###
PROTECTED_BRANCHES=("main" "dev" "feature/diiaNewBranch")
DELETE_LOCAL=false
DELETE_REMOTE=true
### === END CONFIG === ###

# Check if inside a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Not inside a git repository."
    exit 1
fi

echo "Protected branches:"
printf ' - %s\n' "${PROTECTED_BRANCHES[@]}"
echo

echo "Scanning local branches..."
ALL_LOCAL_BRANCHES=$(git for-each-ref --format='%(refname:short)' refs/heads/)

BRANCHES_TO_DELETE=()

# Function to check if branch is protected
is_protected() {
    local branch="$1"
    for pb in "${PROTECTED_BRANCHES[@]}"; do
        if [[ "$branch" == "$pb" ]]; then
            return 0
        fi
    done
    return 1
}

# Find branches to delete
for branch in $ALL_LOCAL_BRANCHES; do
    if ! is_protected "$branch"; then
        BRANCHES_TO_DELETE+=("$branch")
    fi
done

echo "Branches to delete:"
printf ' - %s\n' "${BRANCHES_TO_DELETE[@]}"
echo

read -r -p "Delete these branches? (y/N): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
    echo "Aborted."
    exit 0
fi

# Delete branches
for b in "${BRANCHES_TO_DELETE[@]}"; do
    echo "Deleting: $b"

    if [[ "$DELETE_LOCAL" == true ]]; then
        git branch -D "$b" 2>/dev/null || true
    fi

    if [[ "$DELETE_REMOTE" == true ]]; then
        git push origin --delete "$b" 2>/dev/null || true
    fi
done

echo "Done."

