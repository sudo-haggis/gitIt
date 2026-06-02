#!/bin/bash
SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
source "$SCRIPT_DIR/functions/cli_tools.sh"
source "$SCRIPT_DIR/functions/git_status.sh"
init_colours

echo -e "${BLUE}"
cat <<'EOF'
        _ __  __________
  ___ _(_) /_/  _/_  __/
 / _ `/ / __// /  / /
 \_, /_/\__/___/ /_/
/___/
EOF
echo -e "${NC}"

gitIt() {
    local mode="compact"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                mode="help"; shift ;;
            -v|--verbose)
                mode="verbose"; shift ;;
            -l|--list)
                mode="list"; shift ;;
            -b|--branches)
                SHOW_BRANCHES=true; shift ;;
            -s)
                shift ;;
            -d|--dir)
                if [ -z "$2" ]; then
                    echo "Error: No directory path provided."
                    echo "Usage: gitit -d <directory>"
                    exit 1
                fi
                if [ ! -d "$2" ]; then
                    echo "Error: '$2' is not a valid directory."
                    exit 1
                fi
                SEARCH_DIR="$(cd "$2" && pwd)"; shift 2 ;;
            -t|--test-dir)
                TEST=true
                SEARCH_DIR="tests/fake_file_system"
                echo "Testing directory set to: $SEARCH_DIR"
                shift ;;
            --ignore-repo)
                if [ -z "$2" ]; then
                    echo "Error: No ignore pattern provided."
                    echo "Usage: gitit --ignore-repo <REGEX pattern>"
                    exit 1
                fi
                mode="ignore"
                IGNORE_PATTERN="$2"; shift 2 ;;
            *)
                if [ -d "$1" ]; then
                    SEARCH_DIR="$(cd "$1" && pwd)"; shift
                else
                    echo "Error: Unknown argument '$1'. Use -h for help."
                    exit 1
                fi ;;
        esac
    done

    case "$mode" in
        help)
            echo "                                   gitIt CLI Tool"
            echo "============================================================================================="
            echo "This tool provides a quick report of all local repositories found on your system."
            echo "============================================================================================="
            echo "                               Usage: gitit [flags]"
            echo
            echo "Flags:"
            echo "  -h, --help            Show this help message"
            echo "  -v, --verbose         Full output for all repositories, including clean ones"
            echo "  -b, --branches        Show branch count, merged and stale breakdown per repo"
            echo "  -d, --dir <path>      Run against a specific directory instead of the current one"
            echo "  -l, --list            List found repositories without status detail"
            echo "  -t, --test-dir        Run against the built-in test fixture directory"
            echo "  --ignore-repo <REGEX> Add a pattern to the ignore list (~/.config/gitit/ignore.conf)"
            echo
            echo "Flags can be combined, e.g: gitit -d ~/projects -b -v"
            exit 0 ;;
        ignore)
            __init__
            if [ ! -f "$HOME/.config/gitit/ignore.conf" ]; then
                mkdir -p "$HOME/.config/gitit"
                touch "$HOME/.config/gitit/ignore.conf"
            fi
            if [ -f "$repo_list" ]; then
                grep -E "$IGNORE_PATTERN" "$repo_list" >> "$ignore_list"
                echo "Ignore pattern '$IGNORE_PATTERN' added to $HOME/.config/gitit/ignore.conf"
            else
                echo "No repositories found."
            fi ;;
        list)
            __init__
            [ -f "$repo_list" ] && quick_report || echo "No repositories found."
            exit 0 ;;
        verbose)
            __init__
            quick_report
            generate_status ;;
        compact)
            __init__
            generate_compact ;;
    esac
}

gitIt "$@"
