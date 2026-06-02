#!/bin/bash
git_status_line() {
    local input_path=$1
    local abs_path=""
    if [[ "$input_path" = /* ]]; then
        abs_path="$input_path"
    else
        abs_path="$(pwd)/$input_path"
    fi

    if [ ! -d "$abs_path" ] || ! git -C "$abs_path" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        return 1
    fi

    local repo_name=$(basename "$(git -C "$abs_path" rev-parse --show-toplevel)")
    local staged=$(git -C "$abs_path" diff --cached --name-only | wc -l)
    local modified=$(git -C "$abs_path" diff --name-only | wc -l)
    local branch=$(git -C "$abs_path" branch --show-current)

    local diverge=""
    if [ -n "$branch" ] && [ "$branch" != "main" ] && [ "$branch" != "master" ]; then
        local base=""
        git -C "$abs_path" rev-parse --verify main >/dev/null 2>&1 && base="main"
        [ -z "$base" ] && git -C "$abs_path" rev-parse --verify master >/dev/null 2>&1 && base="master"
        if [ -n "$base" ]; then
            local ahead=$(git -C "$abs_path" rev-list "${base}..HEAD" --count 2>/dev/null)
            local behind=$(git -C "$abs_path" rev-list "HEAD..${base}" --count 2>/dev/null)
            [ "${ahead:-0}" -gt 0 ] && diverge+=" ↑${ahead}"
            [ "${behind:-0}" -gt 0 ] && diverge+=" ↓${behind}"
        fi
    fi

    if [ $((staged + modified)) -eq 0 ]; then
        echo -e "${GREEN}${repo_name}${NC} (0)${diverge}"
    else
        local parts=""
        [ "$staged" -gt 0 ] && parts="${staged} staged"
        [ "$modified" -gt 0 ] && parts="${parts:+$parts, }${modified} modified"
        echo -e "${YELLOW}${repo_name}${NC} (${parts})${diverge}"
    fi
}

git_status() {
    local status_result=""
    local abs_path=""
    local input_path=$1
    if [[ "$input_path" = /* ]]; then
        abs_path="$input_path"
    else
        abs_path="$(pwd)/$input_path"
    fi

    if [ ! -d "$abs_path" ]; then
        ls -la $abs_path
        status_result="$abs_path is not a directory"
        echo "$status_result"
        return 1
    fi

    if ! git -C "$abs_path" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        status_result="Not a repo\n $abs_path"
        echo -e "${RED}$status_result${NC}"
        return 1
    else
        local repo_name=$(basename "$(git -C "$abs_path" rev-parse --show-toplevel)")
        local branch=$(git -C "$abs_path" branch --show-current)
        local staged=$(git -C "$abs_path" diff --cached --name-only | wc -l)
        local modified=$(git -C "$abs_path" diff --name-only | wc -l)

        local diverge=""
        if [ -n "$branch" ] && [ "$branch" != "main" ] && [ "$branch" != "master" ]; then
            local base=""
            git -C "$abs_path" rev-parse --verify main >/dev/null 2>&1 && base="main"
            [ -z "$base" ] && git -C "$abs_path" rev-parse --verify master >/dev/null 2>&1 && base="master"
            if [ -n "$base" ]; then
                local ahead=$(git -C "$abs_path" rev-list "${base}..HEAD" --count 2>/dev/null)
                local behind=$(git -C "$abs_path" rev-list "HEAD..${base}" --count 2>/dev/null)
                [ "${ahead:-0}" -gt 0 ] && diverge+=" ↑${ahead} ahead of ${base}"
                [ "${behind:-0}" -gt 0 ] && diverge+=" ↓${behind} behind ${base}"
            fi
        fi

        status_result+="Found $repo_name on branch $branch${diverge}"$'\n'
        status_result+="Files: ${staged} staged, ${modified} modified"$'\n'
        status_result+=""$'\n'

        if [ $staged -gt 0 ] || [ $modified -gt 0 ]; then
            local git_short_status=$(git -C "$abs_path" status -s --untracked-files=no | head -8)$'\n'
            status_result+="$git_short_status"
        else
            status_result+="Clean tree"
        fi
    fi
    echo -e "$status_result"
}
