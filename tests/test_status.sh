#!/bin/bash
STASH=""

source "functions/git_status.sh"
while IFS= read -r repo; do
    echo "===Repo: $repo ==="
    git_status "$repo"
    echo
done < "/tmp/repositories.txt"

