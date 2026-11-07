#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
    printf 'Usage: %s <pair_id>\n' "$0" >&2
    exit 2
fi

mission_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
env_file="$mission_dir/.env"

if [ ! -f "$env_file" ]; then
    printf 'Missing %s; copy .env.example to .env and configure the pair first.\n' "$env_file" >&2
    exit 1
fi

pair_id=$(sed -n 's/^PAIR_ID=//p' "$env_file")
case "$pair_id" in
    ''|*[!A-Za-z0-9_-]*)
        printf 'PAIR_ID in .env must contain only letters, numbers, underscores, or hyphens.\n' >&2
        exit 1
        ;;
esac

if [ "$1" != "$pair_id" ]; then
    printf 'Requested pair %s does not match configured pair %s.\n' "$1" "$pair_id" >&2
    exit 1
fi

cd "$mission_dir"
docker compose down
rm -f organizer/flag.txt organizer/support-staff.htpasswd organizer/support-staff-credentials.txt
sh prepare-mission.sh
docker compose up -d --build --force-recreate
