#!/bin/bash
#  gitIt CLI Tool
#  This script provides a command-line interface to manage and print reports of local Git repositories.
#source "$(dirname $(pwd))"/git_status.sh
#source "./git_status.sh"

__init__() {
    ##  Establishes variables for the script  ##

    ##  sets the search directory to the home directory
    # or runs only in testing fake_ directory
    if [ ! $TEST ]; then
        SEARCH_DIR="$(pwd)"
    fi

    ##  sets the ignore list file path
    ignore_list="$HOME/.config/gitit/ignore.conf"
    ##  sets the path for the temporary repository list file
    repo_list="/tmp/repositories.txt"
    ##  sets the path for the report file
    report="/tmp/repositories_report.txt"
    ##  sets the path for the git status output file
    status="/tmp/git_status_output.txt"

## removes the temporary repositories.txt file if it exists
    if [ -f "$repo_list" ]; then
        rm "$repo_list"
    fi

## removes the report file if it exists
    if [ -f "$report" ]; then
        rm "$report"
    fi

##  generates sorted list of repositories
    echo "                              *gitting* repositories..."
    ##  searches for .git directories
    find "$SEARCH_DIR" -type d -name ".git" 2>/dev/null | while read -r git_dir; do
        ##  gets the parent directory of the .git directory
        repo_dir=$(dirname "$git_dir")
        ## checks the ignore.conf file for the repository path, ignoring it if present
        if grep -q "$repo_dir" "$ignore_list" 2>/dev/null; then
            echo "INFO: Ignoring $repo_dir!"
            continue
        else
        ##  appends the repository path to a temporary repositories.txt file
            echo "$repo_dir" >> "$repo_list"
        fi
    done

    ## sorts the repository list and removes duplicates
    sort -u "$repo_list" -o "$repo_list"
    ## creates report text file
    nl -w 2 -s '. ' "$repo_list" > "$report"
}

quick_report() {
##  Generates a quick report of all local repositories found in the search director
##  prints a quick report of the repositories found
    echo -e "${RED}=========================================================================================${NC}"
    echo "Found $(wc -l "$repo_list" | awk '{print $1}') active repositories:"
    cat "$report"
    echo -e "${RED}=========================================================================================${NC}"
}

generate_status(){
    if [ -f "$repo_list" ]; then
        echo "             Generating git status for all repositories..."
        echo -e "${RED}=========================================================================================${NC}"
            echo -e "${GREEN}≡≡≡≡≡≡≡≡≡≡≡≡≡≡${NC}"

            while IFS= read -r repo; do
                git_status "$repo"
                echo -e "${GREEN}≡≡≡≡≡≡≡≡≡≡≡≡≡≡${NC}"
            done < "$repo_list"
        echo -e "${RED}=========================================================================================${NC}"
    else
        echo "No repositories found."
    fi
    exit 0
}

init_colours() {
    # Colors for output
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Colors
}
