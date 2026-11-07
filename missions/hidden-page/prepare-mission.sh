#!/bin/sh
set -eu

mission_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
organizer_dir="$mission_dir/organizer"
flag_file="$organizer_dir/flag.txt"
htpasswd_file="$organizer_dir/support-staff.htpasswd"
credentials_file="$organizer_dir/support-staff-credentials.txt"

for file in "$flag_file" "$htpasswd_file" "$credentials_file"; do
    if [ -e "$file" ]; then
        printf 'Mission data already exists at %s; use reset-mission.sh to rotate it.\n' "$file" >&2
        exit 1
    fi
done

if ! command -v openssl >/dev/null 2>&1; then
    printf 'openssl is required to prepare this mission.\n' >&2
    exit 1
fi

umask 077
mkdir -p "$organizer_dir"
chmod 700 "$organizer_dir"

flag="FLAG{$(openssl rand -hex 12)}"
password="Aurelion-$(openssl rand -hex 8)"
password_hash=$(printf '%s\n' "$password" | openssl passwd -apr1 -stdin)

printf '%s\n' "$flag" > "$flag_file"
printf 'support-staff:%s\n' "$password_hash" > "$htpasswd_file"
printf 'Username: support-staff\nPassword: %s\n' "$password" > "$credentials_file"
chmod 400 "$flag_file" "$htpasswd_file" "$credentials_file"

printf 'Prepared private mission data in %s\n' "$organizer_dir"
