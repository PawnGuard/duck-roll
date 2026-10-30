# PawnGuard --- Operation Duck Hunt

## Workshop and CTF Organization & Implementation Guide

**Version:** Operational Draft 1.0\
**Audience:** Organizers, infrastructure leads, and facilitators\
**Total duration:** 120 minutes\
**Format:** Theory → demonstration → attack-and-defense CTF\
**Level:** Beginner to beginner-intermediate\
**Platform:** Linux, Docker, and prepared USB HID boards

------------------------------------------------------------------------

## 1. Executive Summary

Operation Duck Hunt is a hands-on cybersecurity workshop in which each match pits an attacker against a defender. A prepared USB HID device starts the mission and provides a clue. The attacker investigates a lab service and attempts to obtain a flag; the defender identifies and mitigates the vulnerability, then verifies that the legitimate service continues to work.

The workshop does not use a traditional numerical scoring system. Each match has one of the following outcomes:

- **Attacker victory:** submits a valid flag before the defender neutralizes the target.
- **Defender victory:** identifies the vulnerability, applies an effective mitigation, and verifies it.
- **Time expired:** the defender wins by event rules, provided they have not sabotaged the service or violated the rules.

The agreed infrastructure uses Linux on the workstations and Docker on each defender's Linux machine. All teams will be on a single isolated local network. **Six or more simultaneous matches** are expected.

> **Design decision:** a flat network is simple, but it does not provide isolation between pairs. The scope is restricted through dedicated workstations, firewall rules, services listening only where appropriate, and no routes to the school network or the Internet. If strong isolation between pairs is required, port-level filtering, client isolation supported by the network equipment, or separate VLANs/subnets must be added.

## 2. Learning Objectives

By the end, participants should be able to:

1. Explain what a USB HID device is and recognize a preconfigured input sequence.
2. Navigate Linux: terminal, paths, files, and permissions.
3. Understand IP addresses, ports, and the client-server model.
4. Interact with practice services such as SSH, HTTP, FTP, and SMB.
5. Recognize a weak configuration or an exposed resource.
6. Read relevant logs and relate them to observed activity.
7. Apply a specific mitigation and verify that it works.
8. Work within an authorized scope and document the outcome.

The workshop is not intended to teach firmware programming from scratch or cover advanced exploitation. HID profiles, services, and lab vulnerabilities are prepared in advance.

## 3. Format and Schedule (120 minutes)

| Time | Activity | Duration |
|---|---|---:|
| 00:00–00:05 | Welcome, objectives, and rules | 5 min |
| 00:05–00:30 | Technical theory | 25 min |
| 00:30–00:40 | Guided demonstration | 10 min |
| 00:40–01:05 | Round 1 | 25 min |
| 01:05–01:15 | Role swap and reset | 10 min |
| 01:15–01:40 | Round 2 | 25 min |
| 01:40–02:00 | Wrap-up, results, and feedback | 20 min |

For each round, it is recommended that the effective attack time be clearly announced—for example, 15 minutes—and that the remaining time be reserved for defensive response, verification, and recording the outcome. If the preference is to run each 25-minute period as one continuous match, a single rule must be established and announced before the CTF.

Each team must attack once and defend once. The exact number of teams and final rotation will be adjusted to the available workstations.

## 4. Theory Topics (25 minutes)

The material can be presented using brief slides:

1. Introduction to cybersecurity and CTFs.
2. Microcontrollers: Raspberry Pi Pico W and compatible Arduino boards.
3. USB HID: how keyboard emulation works.
4. Firmware and mission profiles.
5. Linux, terminal, and shell.
6. Files, paths, and permissions in Linux.
7. Networking: IP, ports, TCP, and client-server.
8. Services: SSH, HTTP, FTP, and SMB.
9. Authentication, authorization, and credentials.
10. Basic reconnaissance and clue solving.
11. Logs and activity detection.
12. Mitigation, least privilege, and verification.
13. Flags, victory conditions, and match objectives.
14. Authorized scope and lab rules.

**Recommended approach:** explain only the concepts participants will need immediately for the missions. Do not turn the theory portion into an extensive tools lesson.

## 5. Demonstration (10 minutes)

Use a demonstration mission separate from the instances that will be used in the CTF.

1. Connect the prepared HID board and show that Linux recognizes it as an input device.
2. Run a harmless sequence that opens an allowed application or displays a clue.
3. Follow the clue to a local service.
4. Find a demonstration flag.
5. Review a log related to the action.
6. Apply a mitigation and verify that the legitimate service continues to work.

Do not reveal the flags, credentials, or clues for the actual missions. Before the event, verify the board's HID compatibility, firmware, library used, and operating system; not all boards or firmware support USB HID in the same way.

## 6. Infrastructure Design

### 6.1 Components per Match

Each match requires:

- One attacker Linux workstation.
- One defender Linux workstation.
- An Ethernet connection to the dedicated switch.
- A mission running in Docker on the defender's machine.
- An HID board with the assigned profile, or a backup clue-delivery method.
- A way to inspect logs and apply the mitigation.
- A verification and reset procedure.

For six simultaneous matches, the baseline is **12 participant workstations**, plus the organizers' equipment. The HID board can rotate between workstations if logistics allow, although having one per match will make things run more smoothly.

### 6.2 Logical Topology

```text
                         Dedicated physical network
                         (no uplink to campus)
                                  |
                          [Ethernet Switch]
                                  |
                 +-----------------+------------------+
                 |                 |                  |
           [Match 1]          [Match 2]          [Match 6+]
           Attacker A         Attacker B         Attacker F
           Defender A         Defender B         Defender F
           Docker A           Docker B           Docker F
```

Each defender hosts their Docker mission locally. The attacker connects to the defender machine's IP address and the mission's published port. There is no need for a central machine hosting all containers.

### 6.3 DHCP and Addressing

A conventional Ethernet switch usually does not assign IP addresses by itself. DHCP requires one of the following:

- A dedicated router with a DHCP server and no connection to external networks.
- An organizer-operated DHCP server connected to the isolated network.
- A switch that actually includes a configurable DHCP server.

Example subnet, provided it does not conflict with another lab network:

- Network: `192.168.50.0/24`
- DHCP server: `192.168.50.1`
- Dynamic range for workstations: `192.168.50.100–192.168.50.220`
- DHCP reservations or static addresses for defenders: `192.168.50.21–192.168.50.26`
- Attacker workstations: dynamic assignment within the range reserved for clients.

Example defender addresses:

| Match | Defender IP | Example mission port |
|---:|---|---:|
| 1 | `192.168.50.21` | `8081` |
| 2 | `192.168.50.22` | `8082` |
| 3 | `192.168.50.23` | `8083` |
| 4 | `192.168.50.24` | `8084` |
| 5 | `192.168.50.25` | `8085` |
| 6 | `192.168.50.26` | `8086` |

The ports are illustrative. Each mission should publish only the ports it needs. SSH, FTP, and SMB can use their standard ports if each defender has their own IP, or documented alternative ports. Do not use example reservations or addresses without checking the actual DHCP range.

### 6.4 Flat Network Warning

All devices on the same Ethernet subnet can attempt to communicate with one another. A flat network **does not** guarantee that an attacker can reach only their assigned defender.

Minimum controls:

- Dedicated switch with no uplink to the school network or the Internet.
- Do not enable forwarding between networks or alternative routes.
- Host firewall on each defender, limiting mission ports to the appropriate workstations or ranges.
- Publish Docker ports on the lab interface, not indiscriminately on all interfaces.
- Disable host services that are not needed.
- Do not use personal credentials or real data.
- From an attacker workstation, verify that administrative services and targets outside the authorized scope cannot be accessed.

If the requirement is that each attacker can communicate only with their assigned defender, an additional control is required: port/client isolation supported by the switch, appropriate ACLs, or VLANs/subnets for each pair. Do not describe a flat network as strong isolation.

## 7. Docker on Each Defender's Machine

### 7.1 Deployment Principles

- Use Docker Engine and Docker Compose on Linux.
- Keep one Compose folder per mission.
- Run one instance per defender/match, with its own flags and accounts.
- Use small, pinned image versions; prefer images that have been reviewed and built before the workshop.
- Publish only the required ports.
- Run processes as a non-root user whenever feasible.
- Do not use `privileged: true` or mount `/var/run/docker.sock` inside missions.
- Do not mount sensitive host directories into containers.
- Do not store organizer secrets in images or files accessible to participants.
- Limit CPU and memory resources to prevent a mission from affecting the workstation.

### 7.2 Suggested Repository Structure

```text
operation-duck-hunt/
├── README.md
├── missions/
│   ├── hydras-trial/
│   │   ├── compose.yaml
│   │   ├── Dockerfile
│   │   └── config/
│   ├── hidden-page/
│   │   ├── compose.yaml
│   │   ├── Dockerfile
│   │   └── web/
│   ├── anonymous-leak/
│   │   ├── compose.yaml
│   │   └── ftp/
│   ├── shared-secrets/
│   │   ├── compose.yaml
│   │   └── samba/
│   ├── broken-permissions/
│   │   ├── compose.yaml
│   │   └── files/
│   ├── log-hunter/
│   │   ├── compose.yaml
│   │   └── config/
│   ├── name-game/
│   │   ├── compose.yaml
│   │   └── dns/
│   └── api-misconfigured/
│       ├── compose.yaml
│       └── app/
├── profiles/
│   ├── ssh/
│   ├── http/
│   └── ftp/
├── organizer/
│   ├── reset-mission.sh
│   ├── verify-flag.sh
│   └── checklist.md
└── docs/
    ├── organizer-runbook.md
    └── participant-rules.md
```

This structure is an organizational proposal; each directory must be completed with the mission's configuration files, tests, and documentation before it is used.

### 7.3 Minimal Compose Example for an HTTP Mission

Conceptual example for a lab web service. Replace `./web` with an application reviewed and prepared by the organizers. Do not use a random vulnerable image or application on a shared network.

```yaml
services:
  hidden-page:
    build: .
    container_name: duckhunt-hidden-page
    restart: unless-stopped
    ports:
      # Publish on the defender's lab IP, not on all interfaces.
      - "${LAB_HOST_IP}:8080:8080"
    read_only: true
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    mem_limit: 256m
    cpus: 0.50
```

Create a local `.env` file for the defender, for example:

```dotenv
LAB_HOST_IP=192.168.50.21
```

The service inside the container must listen on `0.0.0.0:8080` within its own network namespace. The published address must be the defender's IP on the lab network. Test the file with `docker compose config` before starting. The availability of options such as `mem_limit` depends on the execution mode and Compose version; validate them on the actual machines.

### 7.4 Start, Inspect, and Reset

From a mission directory:

```bash
# Validate the configuration
docker compose config

# Build and start
docker compose up -d --build

# Check status and logs
docker compose ps
docker compose logs --tail=100

# Stop and remove the project's containers and networks
docker compose down

# Deploy again
docker compose up -d --build
```

**Important:** recreating containers does not automatically reset data stored in persistent volumes, bind mounts, or host directories. Prepare a mission-specific reset function that restores files, accounts, permissions, flags, and vulnerable configuration. Do not run `docker compose down -v` indiscriminately: it can delete volumes that need to be preserved.

### 7.5 What a "Clean Reset" Means

Before the next round, the person in charge must verify that:

- The container is in the expected initial state.
- The fictional test credentials have been restored.
- Decoy files and permissions have returned to their initial configuration.
- The flag corresponds to the current round or instance.
- The necessary logs have been archived for review, and it has been defined which logs will be cleared.
- The legitimate service responds again.
- No processes, ports, temporary files, or residual changes remain on the host.

## 8. Proposed Missions

Eight missions are proposed to provide variety. It is not necessary to run all eight during a two-hour workshop; each pair receives one mission, and the selection is adjusted to the available hardware, preparation, and skill level.

### 8.1 Hydra's Trial — SSH

**Level:** Beginner–intermediate.\
**Concepts:** SSH, authentication, logs, and mitigation.

- **Scenario:** a fictional account has a deliberately weak password.
- **Attacker:** follows the clue, identifies the lab account, and tests a small prepared wordlist against that one server.
- **Defender:** checks authentication logs, identifies repeated attempts, and fixes the account or authentication policy.
- **Attacker victory:** submits the protected flag before mitigation.
- **Defender victory:** changes or disables the test account, verifies that the previous credential no longer works, and confirms that legitimate access remains available.

Limits: one fictional account, one assigned host, a small wordlist, and bounded frequency and duration. Do not use real passwords, leaked lists, or other machines. Hydra is used only within the authorized instance.

### 8.2 Hidden Page — HTTP

**Level:** Easy.\
**Concepts:** HTTP, paths, resource exposure, and logs.

- **Scenario:** a practice route is intentionally exposed.
- **Attacker:** finds the route and obtains the lab flag.
- **Defender:** identifies the request in the logs and restricts the route without breaking the rest of the site.
- **Verification:** the route is no longer available to an unauthorized user, and the legitimate page continues to work.

### 8.3 Anonymous Leak — FTP

**Level:** Easy–intermediate.\
**Concepts:** FTP, anonymous access, and permissions.

- **Scenario:** a decoy file can be downloaded through anonymous access.
- **Attacker:** finds and retrieves the test file.
- **Defender:** disables anonymous access or corrects permissions.
- **Verification:** the file can no longer be obtained without authorization, and legitimate access continues to work.

### 8.4 Shared Secrets — SMB/Samba

**Level:** Easy–intermediate.\
**Concepts:** shared folders, permissions, and accounts.

- **Scenario:** a shared folder contains fictional data with overly broad permissions.
- **Attacker:** finds the resource and the flag.
- **Defender:** adjusts permissions and user-based access.
- **Verification:** the unauthorized user loses access, while the legitimate user retains the access they need.

### 8.5 Broken Permissions — Linux

**Level:** Easy.\
**Concepts:** ownership, permissions, and least privilege.

- **Scenario:** a practice file is readable or modifiable by a user who should not have access.
- **Attacker:** demonstrates the improper access and locates the flag.
- **Defender:** corrects ownership, permissions, and privileges.
- **Verification:** improper access fails and the application remains operational.

The mission must be restricted to the practice filesystem or container; sensitive host files must never be exposed.

### 8.6 Log Hunter — Logs

**Level:** Easy–intermediate.\
**Concepts:** observability, correlation, and response.

- **Scenario:** benign, predefined events are generated within the mission.
- **Defensive objective:** identify the activity, point out evidence in the logs, and explain the appropriate response.
- **Victory:** the organizer confirms that the defender identified the correct event and documented the evidence.
- **Variant:** a flag can appear when a specific event is found, without requiring any additional exploitation.

### 8.7 Name Game — DNS

**Level:** Easy–intermediate.\
**Concepts:** DNS and name resolution.

- **Scenario:** a local practice DNS service resolves a name that leads to the next clue.
- **Attacker:** queries the assigned DNS service and follows the returned name.
- **Defender:** detects and corrects an entry or exposure configured for the exercise.
- **Verification:** name resolution behaves according to the intended secure configuration.

On a flat network, do not allow the practice DNS service to accidentally become the resolver for the entire school network.

### 8.8 API Misconfigured — HTTP API

**Level:** Intermediate.\
**Concepts:** endpoints, authentication, and authorization.

- **Scenario:** a lab endpoint returns decoy data without properly checking authorization.
- **Attacker:** identifies the endpoint and obtains the flag by exploiting the intentional flaw.
- **Defender:** implements or enables the authorization check.
- **Verification:** the unauthorized user receives a denied response, and the legitimate workflow continues.

All missions must have a private organizer guide, a known vulnerable state, a defensive solution, a test flag, hints, and a verified reset procedure.

## 9. USB HID and Mission Profiles

Organizers provide profiles or prebuilt firmware; participants should not have to program from scratch during the workshop.

Each profile should:

1. Identify the mission or provide an initial clue.
2. Perform only harmless and predictable actions on the prepared system.
3. Tell the participant which lab service to investigate, without exposing credentials from other matches.
4. Avoid persistent changes, access to personal data, or actions outside the authorized scope.

Test each profile on the exact operating system that will be used during the workshop. Have a printed or manual clue available as a backup in case a board fails. HID should not have administrative privileges or disable security controls.

## 10. Match Rules and Victory Conditions

### Attacker Victory

- Submits a valid flag to the organizer before the defense neutralizes the target.
- A flag that has been obtained counts as a victory even if mitigation is applied afterward.

### Defender Victory

- Identifies the vulnerability or insecure configuration.
- Applies a real fix.
- Verifies that the vulnerability no longer works.
- Confirms that the legitimate service remains available.

### Time Expired

- The defender wins, provided they have followed the rules and have not caused an arbitrary service outage.

### Actions That Do Not Count as Valid Mitigations

- Shutting down all services without diagnosing the issue.
- Disconnecting the workstation or sabotaging the match.
- Claiming that something was fixed without verifying it.
- Deleting evidence needed for review.

### Penalties

Penalties must be published before the CTF and applied consistently. In a beginner activity, asking for help should not be penalized; free hints or progressive assistance are preferable. If organizers want to penalize operational violations, they must specify the deduction and procedure in advance. Any attempt to leave the authorized scope must be stopped immediately and reviewed with the organizer.

There is no points table or scoring portal. The match outcome and the evidence needed to validate it are recorded.

## 11. Rotation and Simultaneous Matches

Six simultaneous pairs require at least twelve participant workstations and six independent mission instances, one on each defender's machine.

Example rotation for six teams:

| Team | Round 1 | Round 2 |
|---|---|---|
| A | Attack SSH | Defend HTTP |
| B | Attack HTTP | Defend FTP |
| C | Attack FTP | Defend SMB |
| D | Attack SMB | Defend SSH |
| E | Attack Broken Permissions | Defend Log Hunter |
| F | Attack Log Hunter | Defend Broken Permissions |

This is an example; the final matrix must ensure that everyone attacks once and defends once, and that each defender has a deployed and tested mission. DNS and API can replace missions depending on the group's experience. Prevent one pair from accidentally using another pair's instance.

## 12. Recording Results

The organizer can use a local spreadsheet with the following columns:

- Date and round number.
- Pair/team identifier.
- Role.
- Mission.
- Outcome: flag, mitigation, or time expired.
- Flag validated (yes/no; do not include the secret value in a shared spreadsheet).
- Mitigation and observed verification.
- Penalty, if applicable, and reason.
- Incident or technical issue.
- Organizer's initials confirming validation.

A scoring platform is not necessary. A visible shared timer and a local spreadsheet are sufficient. Before the workshop, confirm that the timer works without relying on an external connection if the lab network will be completely isolated.

## 13. Organizer Team Roles

Assign these responsibilities explicitly; one person can cover more than one role if the team is small.

- **Coordinator:** announces the rules, manages the schedule, and handles issues.
- **Infrastructure lead:** verifies the switch, DHCP, IP addresses, isolation, and firewall.
- **Mission lead:** prepares Compose, accounts, flags, and reset procedures.
- **Technical facilitator:** presents the theory and runs the demo.
- **Referee/validator:** confirms flags, mitigations, and results.
- **Workstation support:** helps recover HID profiles or troubleshoot equipment failures.

## 14. Preparation

### One Week or Several Days Before

- Define the number of pairs, teams, and HID boards.
- Prepare and review the Docker images.
- Create mission guides for participants and the organizer's private solution guide.
- Confirm addresses, ports, and the person responsible for each machine.
- Prepare firewall rules and the isolation procedure.
- Establish expected outcomes and victory criteria.
- Test HID compatibility on all workstations.

### The Day Before

- Deploy the six or more simultaneous instances.
- Run one end-to-end test match for each mission.
- Confirm that flags are valid and are not improperly reused.
- Verify that the defender can fix the issue without taking down the legitimate service.
- Rehearse the reset procedure and measure restoration time.
- Check access to logs.
- Disconnect any uplink to the school network/Internet.
- Verify that no alternative routes exist.

### Before Doors Open

- Confirm DHCP and connectivity for all workstations.
- Confirm that each attacker can reach only the address/port of their mission, to the extent allowed by the network design.
- Confirm that Docker administration is not accessible from the participant network.
- Start the timer and have printed instructions ready.
- Save a clean copy of the configurations and an IP/port list for organizers.

## 15. Security Checklist

- [ ] Dedicated physical network with no external uplink.
- [ ] No personal data or real credentials.
- [ ] Accounts and passwords are fictional only.
- [ ] Docker services are published only on the required ports.
- [ ] Host firewall is configured and tested.
- [ ] Docker administration port/socket is not exposed to participants.
- [ ] Containers are not privileged and have no sensitive host mounts.
- [ ] Resource limits are set for practice services.
- [ ] A different flag is used per instance/round where appropriate.
- [ ] Logs are available for review.
- [ ] Reset procedure has been tested.
- [ ] Mitigations have been tested and the legitimate service verified.
- [ ] Immediate shutdown procedure is in place for activity outside the authorized scope.
- [ ] Infrastructure lead and referee have been identified.

## 16. Wrap-Up and Retrospective (20 minutes)

1. Announce match results without revealing secret credentials.
2. Ask defenders to explain what evidence they observed and what mitigation they applied.
3. Review the difference between obtaining a flag and fixing the vulnerability.
4. Briefly show the logs and final state of a demonstration mission.
5. Gather feedback: what was confusing, which tools were missing, and which mission was most useful.
6. Confirm that all instances have been stopped or reset and that the lab has been cleaned up.

## 17. Acceptance Criteria for Workshop Readiness

The workshop is ready to run when:

- Six or more simultaneous matches have been tested.
- Each pair has an attacker workstation, a defender workstation, and an assigned mission.
- DHCP and addressing work predictably.
- Services expose only the documented ports.
- Missions can be reset without leaving residue.
- Flags are validated manually and outcomes are recorded.
- Each mission has a verifiable mitigation.
- The HID profile works or a backup clue is available.
- The network is isolated and the authorized scope has been tested.
- All organizers know the schedule, their responsibilities, and the shutdown procedure.

------------------------------------------------------------------------

## Appendix A — Decisions Still to Be Confirmed

Before turning this document into a final runbook, confirm:

1. Exact switch model and whether it supports port/client isolation.
2. Which equipment will provide DHCP (isolated router, dedicated server, or switch feature).
3. Final IP and port allocation.
4. Number of available workstations and HID boards.
5. Which missions will be implemented for the first edition; SSH, HTTP, FTP, and SMB are recommended as a starting point.
6. Whether each round will last the full 25 minutes or have 15 minutes of effective attack time and 10 minutes for response/verification.
7. Whether hints are allowed without penalty (recommended for beginners).

## Appendix B — Technical References for Organizers

Consult the official documentation corresponding to the installed versions:

- Docker Compose: https://docs.docker.com/compose/
- Docker port publishing: https://docs.docker.com/engine/network/port-publishing/
- Docker security: https://docs.docker.com/engine/security/
- Docker Compose CLI: https://docs.docker.com/reference/cli/docker/compose/

Exact options may vary depending on the Linux distribution and Docker version. Test all configurations in the same environment that will be used during the workshop.
