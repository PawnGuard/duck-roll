# Copilot contributor guide

This guide is for contributors implementing Operation Duck Hunt features with
Copilot. It is intentionally structured so one contributor can paste one complete
context into a Copilot chat and receive an implementation that is bounded,
reviewable, and testable.

Read `docs/workshopGuideOverview.md` and `.github/copilot-instructions.md` first.
All work is limited to the isolated workshop network, fictional data, and the
assigned mission. Never test against the school network, the Internet, personal
devices, real credentials, or another team's match.

## Shared one-context workflow

1. Create a branch named for the mission and role, such as
   `red/hidden-page-profile` or `blue/hidden-page-compose`.
2. Start a new Copilot chat and paste the relevant prompt below as one message.
3. Replace every bracketed value before sending it.
4. Ask Copilot to inspect the repository before editing. Do not paste flags,
   passwords, private organizer notes, or device-specific secrets into chat.
5. Review the proposed file list and boundary assumptions before allowing edits.
6. Run the validation commands in the prompt locally on the assigned lab machine.
7. Record the result in the pull request: changed files, authorized scope,
   validation, and remaining assumptions.

## Red Team prompt: MCU/HID mission profile

Copy this entire prompt into a fresh Copilot chat:

```text
You are implementing a Red Team feature for Operation Duck Hunt, an authorized
cybersecurity workshop on an isolated local network. Read
docs/workshopGuideOverview.md and .github/copilot-instructions.md before changing
anything.

Mission: [mission name]
Profile name: [profile name]
Board/firmware/library: [exact board and library]
Prepared workstation OS: [OS and version]
Initial clue: [non-secret clue text]
Assigned service and scope: [defender IP/hostname placeholder and port]
Required participant action: [harmless, deterministic action]
Manual fallback clue: [where it will be stored or displayed]

Implement only the prepared HID/MCU profile under profiles/ (or the existing
repository location). Inspect existing profile conventions and reuse them. The
profile must:
- perform predictable, harmless actions only on the prepared workstation;
- deliver the clue without exposing credentials, flags, or another match;
- avoid persistence, privilege escalation, security-control changes, personal
  data, and access outside the assigned lab service;
- fail safely if the expected device/application is unavailable;
- include concise operator/participant documentation and a manual fallback.

Do not invent hardware APIs or claim that a board supports USB HID without checking
the existing code and exact library. If the repository lacks enough information,
stop and identify the missing assumption instead of guessing.

Before editing, report the files you intend to change and the safety assumptions.
Then implement the smallest complete change. Add focused tests or a deterministic
dry-run/check where the hardware makes automated testing impossible. Validate
syntax/build using the repository's available tooling and explain what must still
be tested on physical hardware. Do not use real targets or credentials.

Finish with:
1. changed files;
2. exact authorized scope;
3. validation commands and results;
4. physical-board checks still required;
5. rollback/reset steps.
```

### Red Team acceptance checklist

- The profile is deterministic and harmless.
- The clue identifies only the assigned mission.
- No flag, password, persistence, privilege escalation, or security-control
  bypass is introduced.
- A physical-board test and printed/manual fallback are documented.
- The profile can be reset or replaced without residue.

## Blue Team prompt: Docker Compose defense mission

Copy this entire prompt into a fresh Copilot chat:

```text
You are implementing a Blue Team feature for Operation Duck Hunt, an authorized
cybersecurity workshop on an isolated local network. Read
docs/workshopGuideOverview.md and .github/copilot-instructions.md before changing
anything.

Mission: [mission name]
Service type: [SSH/HTTP/FTP/SMB/logs/DNS/API]
Mission directory: [path]
Defender lab IP / `LAB_HOST_IP`: [lab IP value]
Required published port(s): [port list]
Intended initial weakness: [fictional, bounded weakness]
Legitimate workflow that must remain available: [workflow]
Expected mitigation: [specific configuration or code change]
Reset requirements: [accounts/files/permissions/flags/logs/volumes]
Verification command or test: [command/check]

Inspect the existing mission structure before editing. Implement the smallest
complete mission change, including Compose configuration, service/configuration
files, documentation, a safe reset procedure, and focused verification where
appropriate.

Keep the mission safe for the isolated workshop:
- use fictional data and credentials only;
- publish only the required port(s), bound to LAB_HOST_IP where supported;
- do not use privileged containers, Docker socket mounts, sensitive host mounts,
  random vulnerable images, or unreviewed external dependencies;
- prefer pinned/reviewed images, non-root execution, read_only filesystems,
  dropped capabilities, no-new-privileges, and CPU/memory limits where compatible;
- keep organizer-only flags and solutions out of participant-facing files and
  images;
- make logs sufficient to identify the activity without leaking secrets;
- do not make `docker compose down -v` the default reset.

Before editing, report the files you intend to change and the security assumptions.
Then implement the change. Validate with:
1. docker compose config;
2. docker compose up -d --build;
3. docker compose ps and bounded logs;
4. a check that only the documented service ports are exposed;
5. the intended initial-state check;
6. the mitigation check showing unauthorized access fails;
7. the legitimate workflow check showing the service still works;
8. the documented reset followed by a clean-state check.

Use only the assigned local lab instance. Never scan or connect to other matches,
the school network, the Internet, or real services. Finish with changed files,
authorized scope, validation results, reset/rollback steps, and any assumptions
that require organizer confirmation.
```

### Blue Team acceptance checklist

- `docker compose config` succeeds on the workshop machine.
- Only documented ports are published on the lab interface.
- The initial weakness is reproducible and bounded.
- Logs support detection without exposing secrets.
- The mitigation blocks the intended unauthorized action.
- The legitimate workflow remains available.
- Reset restores files, accounts, permissions, flags, logs, and data state.
- The container is not privileged and has no sensitive host access.

## Pull request handoff template

Use this in the pull request description:

```text
## Role and mission
- Role:
- Mission:
- Assigned scope:

## Change
- Files:
- Behavior added or fixed:
- Security boundary preserved:

## Validation
- Commands/checks:
- Initial state:
- Mitigation:
- Legitimate workflow:
- Reset:

## Assumptions and follow-up
- Hardware or host-specific checks:
- Organizer decisions needed:
```
