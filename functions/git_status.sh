#!/bin/bash
git_status() {
    # param1 is directory path to deal with 
    local status_result=""
    local abs_path=""
    local input_path=$1
    # Convert relative path to absolute path
    if [[ "$input_path" = /* ]]; then
        # Already absolute path
        abs_path="$input_path"
    else
        # Relative path - combine with current working directory
        abs_path="$(pwd)/$input_path"
    fi
    
    if [ ! -d "$abs_path"  ]; then
        ls -la $abs_path
        status_result="$abs_path is not a directory"
        echo "$status_result"
        return 1
    fi
    
    # If not a git -C "$abs_path "repo return "Not a repo"
    if ! git -C "$abs_path"  rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        status_result="Not a repo\n $abs_path"
        echo -e "${RED}$status_result${NC}"
        return 1
    else 
        # Show some details of the repo
        local repo_name=$(basename $(git -C "$abs_path" rev-parse --show-toplevel))
        local repo_curr_branch=$(git -C "$abs_path" branch --show-current)
        local staged=$(git -C "$abs_path" diff --cached --name-only | wc -l)
        local modified=$(git -C "$abs_path" diff --name-only | wc -l)
        
        # Build status string
        status_result+="Found $repo_name on branch $repo_curr_branch"$'\n'
        status_result+="Files: ${staged} staged, ${modified} modified"$'\n'
        status_result+=""$'\n'  # Empty line for formatting
        
        if [ $staged -gt 0 ] || [ $modified -gt 0 ]; then
            local git_short_status=$(git -C "$abs_path" status -s --untracked-files=no | head -8)$'\n'
            status_result+="$git_short_status"
        else
            status_result+="Clean tree"
        fi
    fi
    echo -e "$status_result"
}
