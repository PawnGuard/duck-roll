# Copilot instructions for Operation Duck Hunt

## Mission and scope

This repository supports an authorized, isolated cybersecurity workshop. Work only on
the local lab, fictional accounts, prepared HID profiles, and assigned mission
instances described in `docs/workshopGuideOverview.md`. Do not add behavior that
targets the school network, the Internet, personal data, real credentials, or
unassigned matches.

Read `docs/workshopGuideOverview.md` before implementing a feature. Treat it as the
source of truth for the workshop topology, team responsibilities, mission limits,
victory conditions, reset expectations, and safety requirements.

## Team boundaries

- **Red Team:** prepared USB HID/MCU firmware and mission profiles. Profiles must
  perform predictable, harmless actions and deliver clues only on the prepared
  workstation. They must not request or require administrative privileges, disable
  security controls, persist changes, access personal data, or leave the assigned
  scope.
- **Blue Team:** Docker Compose missions, service configuration, logging,
  hardening, mitigation, verification, and reset procedures. Services must use
  fictional data, expose only required ports, and be safe to run on the isolated
  lab network.

Do not silently cross the team boundary. If a change needs both teams, document the
interface and keep each implementation in its owning area.

## Implementation defaults

- Prefer small, reviewable changes that match the proposed structure:
  `missions/`, `profiles/`, `organizer/`, and `docs/`.
- Reuse existing scripts and conventions before adding helpers.
- Never use `privileged: true`, mount `/var/run/docker.sock`, or mount sensitive
  host directories into a mission.
- Pin or review image versions; do not introduce random vulnerable images.
- Publish only documented mission ports and bind them to the configured lab
  interface (`LAB_HOST_IP` where applicable).
- Prefer non-root container processes, `read_only`, dropped capabilities,
  `no-new-privileges`, and resource limits where compatible with the mission.
- Keep secrets, flags, credentials, and organizer-only solutions out of participant
  documentation and container images.
- Do not use `docker compose down -v` as a generic reset. Reset bind mounts,
  volumes, accounts, permissions, flags, and logs deliberately.
- Keep firmware actions deterministic and test them on the exact workshop OS and
  board family.

## Required validation

Every feature should include focused documentation and tests or reproducible checks.
At minimum, contributors should:

1. Validate YAML and Compose with `docker compose config` for Compose changes.
2. Build and start the assigned mission, inspect `docker compose ps` and logs, and
   verify only intended ports are reachable.
3. Demonstrate both the intentionally vulnerable/initial state and the defensive
   mitigation, without using real credentials or external targets.
4. Run the mission reset and verify the clean initial state and legitimate service.
5. For HID changes, test the profile on a prepared workstation and retain a manual
   clue fallback.

In the final response, state the files changed, the authorized scope, validation
performed, and any unverified hardware or environment assumptions.
