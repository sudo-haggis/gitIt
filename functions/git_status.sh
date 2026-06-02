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

    # Ahead/behind (plain text, no colour codes — used in length calc too)
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

    # Status text and row colour
    local status_text color
    if [ $((staged + modified)) -eq 0 ]; then
        status_text="(0)"; color="${GREEN}"
    else
        local parts=""
        [ "$staged" -gt 0 ] && parts="${staged} staged"
        [ "$modified" -gt 0 ] && parts="${parts:+$parts, }${modified} modified"
        status_text="(${parts})"; color="${YELLOW}"
    fi

    # Right-hand side: branch counts (--branches) or current branch name (default)
    local right_colored right_plain
    if [ "${SHOW_BRANCHES}" = "true" ]; then
        local br_total br_merged br_stale
        read -r br_total br_merged br_stale <<< "$(git_branch_summary "$abs_path")"
        local t=$(printf '%3d' "${br_total:-0}")
        local m=$(printf '%3d' "${br_merged:-0}")
        local s=$(printf '%3d' "${br_stale:-0}")
        local stale_color="${DIM}"
        [ "${br_stale:-0}" -gt 0 ] && stale_color="${YELLOW}"
        right_colored="${DIM}${ICON_BRANCH}${t}  ✓${m}  ${stale_color}${ICON_STALE}${s}${NC}"
        right_plain="${ICON_BRANCH}${t}  ✓${m}  ${ICON_STALE}${s}"
    else
        local display_branch="${branch:0:30}"
        right_colored="${DIM}${display_branch}${NC}"
        right_plain="${display_branch}"
    fi

    # Leader dots to fill the gap
    local plain_left="${repo_name} ${status_text}${diverge}"
    local term_width=$(tput cols 2>/dev/null || echo 100)
    local dots_len=$(( term_width - ${#plain_left} - ${#right_plain} - 3 ))
    [ "$dots_len" -lt 3 ] && dots_len=3
    local spaces=$(printf '%*s' "$dots_len" '')
    local dots="${DIM}${spaces// /·}${NC}"

    echo -e "${color}${repo_name}${NC} ${status_text}${diverge} ${dots} ${right_colored}"
}

git_branch_summary() {
    # returns three space-separated numbers: total merged stale
    local abs_path=$1
    local total=$(git -C "$abs_path" branch 2>/dev/null | grep -vcE "^\*? *(main|master)$")
    local merged=$(git -C "$abs_path" branch --merged HEAD 2>/dev/null | grep -vcE "^\*? *(main|master)$")
    local now=$(date +%s)
    local stale=0
    while IFS= read -r line; do
        local ts=$(echo "$line" | awk '{print $2}')
        [ -z "$ts" ] && continue
        local age=$(( now - ts ))
        [ "$age" -gt 7776000 ] && stale=$(( stale + 1 ))  # 90 days
    done < <(git -C "$abs_path" for-each-ref --format='%(refname:short) %(committerdate:unix)' refs/heads/ 2>/dev/null \
        | grep -vE "^(main|master) ")
    echo "${total} ${merged} ${stale}"
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
