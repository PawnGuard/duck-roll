#!/bin/sh
set -eu

: "${HYDRAS_FLAG:?HYDRAS_FLAG is required}"
: "${OPERATOR_PUBLIC_KEY:?OPERATOR_PUBLIC_KEY is required}"

printf '%s\n' 'hydra:trial-password' | chpasswd
passwd -u hydra >/dev/null
passwd -d operator >/dev/null
mkdir -p /home/operator/.ssh
chown operator:operator /home/operator/.ssh
chmod 700 /home/operator/.ssh
printf '%s\n' "$OPERATOR_PUBLIC_KEY" > /home/operator/.ssh/authorized_keys
chown operator:operator /home/operator/.ssh/authorized_keys
chmod 600 /home/operator/.ssh/authorized_keys

install -o hydra -g hydra -m 600 /dev/null /home/hydra/flag
printf '%s\n' "$HYDRAS_FLAG" > /home/hydra/flag

exec /usr/sbin/sshd -D -e
