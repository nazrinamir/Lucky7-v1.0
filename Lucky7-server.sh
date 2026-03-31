#!/bin/sh
printf '\033c\033]0;%s\a' Lucky7
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Lucky7-server.x86_64" "$@"
