# Hydra's Trial

Hydra's Trial is an authorized, isolated-workshop SSH mission. The initial
state contains one fictional account with a deliberately weak password. The
defender uses SSH authentication logs to identify the activity, disables the
test account, and verifies that the legitimate operator key still works.

The service publishes only TCP `2222` on `LAB_HOST_IP` and maps it to SSH port
`22` inside the container. Use one instance per assigned match; do not connect
this mission to the school network, the Internet, or another match.

## Defender setup

Create `missions/hydras-trial/.env` on the assigned defender machine. Keep the
flag and private key out of Git:

```dotenv
LAB_HOST_IP=192.168.50.21
HYDRAS_FLAG=replace-with-the-organizer-issued-flag
OPERATOR_PUBLIC_KEY=ssh-ed25519 AAAA... operator@hydras-trial
```

The organizer must issue a unique fictional flag and an operator key pair for
each match. The private key belongs only to the defender/operator and must not
be placed in this directory or exposed to participants.

If an operator key pair has not already been issued, create one outside the
repository and give the organizer only the public key:

```bash
ssh-keygen -t ed25519 -N '' -f "$HOME/.ssh/hydras-trial-operator"
cat "$HOME/.ssh/hydras-trial-operator.pub"
```

Start and inspect the mission:

```bash
docker compose config
docker compose up -d --build
docker compose ps
docker compose logs --tail=100 ssh
```

The participant clue should identify only the assigned defender address and
port: `ssh hydra@<LAB_HOST_IP> -p 2222`. Authentication attempts must remain
bounded to this one host, account, and mission.

## Defensive workflow

Review the SSH logs without exposing credentials:

```bash
docker compose logs --tail=100 ssh
```

Disable the fictional test account after identifying the activity:

```bash
docker compose exec ssh passwd -l hydra
```

Verify the mitigation and the legitimate workflow:

```bash
docker compose exec ssh passwd -S hydra
ssh -i /path/to/operator-key -o IdentitiesOnly=yes \
  -p 2222 operator@${LAB_HOST_IP}
```

The previous `hydra` password must no longer authenticate, while the
operator-key login remains available. Do not print or submit the flag in logs,
documentation, or command output.

## Reset and end-user operation

After the match, restore the clean vulnerable state with the mission-local
reset script. It deliberately removes only this Compose project's container and
network; it does not remove volumes or unrelated Docker resources:

```bash
./reset.sh
docker compose logs --tail=20 ssh
```

The reset recreates the fictional `hydra` account, its runtime flag, and the
operator authorized key from `.env`. Confirm that the service is healthy and
that only the documented `LAB_HOST_IP:2222` listener is exposed. Remove the
local `.env` and operator private key according to the organizer's handling
procedure after the workshop.

## Safety and assumptions

This first iteration uses a reviewed, pinned Alpine base image and builds
OpenSSH locally. The SSH daemon must start with the container's required
startup privileges, but the container is not privileged, has no host mounts,
drops no additional Linux capabilities because OpenSSH and the defensive
workflow must update account state, and has resource limits. The container is
still unprivileged and the root filesystem remains writable because the
defensive workflow must update the fictional account state;
the mission has no persistent volume, so reset removes that runtime state.
Physical HID clue delivery and host firewall enforcement remain organizer checks
outside this mission directory.
