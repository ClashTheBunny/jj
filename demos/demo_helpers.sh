#!/bin/bash
set -euo pipefail
BASE_DIR=$(realpath "$(dirname "$0")")

UPLOAD=false
PREVIEW=false
DEBUG=false
FAST=false
unset TMUX

init() {
    for arg in "$@"; do
        case "$arg" in
        -h|--help)
            echo 'Run a given demo.
Arguments:
  --preview: Preview the asciicast.
  --upload: Upload to asciinema (after previewing, if necessary).
  --debug: Show the asciicast as it is being recorded. Note that what you see
           will not be exactly the same as what is recorded.
'
            exit
            ;;
        --upload)
            UPLOAD=true
            ;;
        --preview)
            PREVIEW=true
            ;;
        --debug)
            DEBUG=true
            ;;
        --fast)
            FAST=true
            ;;
        *)
            echo "Unrecognized argument: $arg"
            exit 1
            ;;
        esac
    done

    tmux kill-session -t demo 2> /dev/null || true
    tmux new-session -d -s demo "PS1='$ ' bash --norc"
    tmux set-option -t demo status off
}

new_tmp_dir() {
    local dirname
    dirname=$(mktemp -d)
    mkdir -p "$dirname"
    cd "$dirname"
    trap "rm -rf '$dirname'" EXIT
}

run_demo() {
    local title="$1"
    local test_script="$2"
    local fast=""
    if [[ "$FAST" == true ]]; then
      fast="set send_human {0.005 0.01 1 0.005 0.1}
proc pause {duration} {
    sleep [expr \$duration / 10.0]
}
"
    fi
    local expect_script="source $BASE_DIR/demo_helpers.tcl
$fast
spawn asciinema rec -c \"tmux attach-session -t demo\" --title \"$title\"
expect_prompt
$test_script
quit_and_dump_asciicast_path
"

    if [[ "$DEBUG" == true ]]; then
        echo "$expect_script" | /usr/bin/env expect
        return
    fi

    echo "Recording demo (terminal size is $(tput cols)x$(tput lines))..."
    if [[ "$PREVIEW" == 'false' ]]; then
        echo '(Pass --preview to play the demo automatically once done)'
    fi
    local asciicast_path
    asciicast_path=$(echo "$expect_script" | /usr/bin/env expect | tail -1)
    echo "$asciicast_path"
    tmux kill-session -t demo 2> /dev/null || true

    if [[ "$PREVIEW" == 'true' ]]; then
        asciinema play "$asciicast_path"
    fi
    if [[ "$UPLOAD" == 'true' ]]; then
        if [[ "$PREVIEW" == 'true' ]] && ! confirm "Upload?"; then
            return
        fi
        : asciinema upload "$asciicast_path"
    fi
}
