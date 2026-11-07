#!/bin/sh
set -eu

flag_file=/run/secrets/hidden_page_flag
if [ ! -r "$flag_file" ]; then
    printf 'Mission flag secret is missing or unreadable.\n' >&2
    exit 1
fi

flag=$(cat "$flag_file")
case "$flag" in
    'FLAG{'*'}') ;;
    *)
        printf 'Mission flag has an invalid format.\n' >&2
        exit 1
        ;;
esac

mkdir -p /tmp/internal/incident-dashboard
sed "s|__FLAG__|$flag|g" \
    /usr/local/share/hidden-page/incident-dashboard.html.template \
    > /tmp/internal/incident-dashboard/index.html

exec nginx -g 'daemon off;'
