#!/bin/sh
set -eu

mission_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
flag_dir="$mission_dir/organizer"
flag_file="$flag_dir/flag.txt"

if [ -e "$flag_file" ]; then
    printf 'A flag already exists at %s; remove it only when rotating the instance.\n' "$flag_file" >&2
    exit 1
fi

if ! command -v openssl >/dev/null 2>&1; then
    printf 'openssl is required to generate a per-instance flag.\n' >&2
    exit 1
fi

umask 077
mkdir -p "$flag_dir"
random_hex=$(openssl rand -hex 12)
printf 'DUCK{%s}\n' "$random_hex" > "$flag_file"
chmod 0444 "$flag_file"
printf 'Created a private flag file at %s\n' "$flag_file"
