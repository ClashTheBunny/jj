#!/bin/bash
set -euo pipefail
. "$(dirname "$0")"/demo_helpers.sh

new_tmp_dir

init "$@"

run_demo 'Clone a Git repo' '
run_command "# Clone a Git repo:"
run_command "jj git clone https://github.com/octocat/Hello-World"
run_command "cd Hello-World"
pause 1
run_command "# Inspect it:"
pause 1
run_command "jj log"
pause 5
run_command "jj diff -r b1"
pause 2
run_command "# The repo is backed by the actual Git repo:"
run_command "git --git-dir=.jj/repo/store/git log --graph --all --decorate --oneline"
'
